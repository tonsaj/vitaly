import Foundation
import GoogleGenerativeAI

// MARK: - AI Insight Cache
private struct CachedInsight: Codable {
    let insight: String
    let hour: Int
    let day: Int
    let dataHash: Int
    let timestamp: Date
}

private class AIInsightCache {
    static let shared = AIInsightCache()

    private let defaults = UserDefaults.standard
    private let cacheKeyPrefix = "ai_insight_cache_"

    func getCached(for key: String, dataHash: Int) -> String? {
        let cacheKey = cacheKeyPrefix + key
        guard let data = defaults.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode(CachedInsight.self, from: data) else {
            return nil
        }

        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentDay = calendar.component(.day, from: now)

        // Cache is valid if same hour, same day, and same data hash
        if cached.hour == currentHour && cached.day == currentDay && cached.dataHash == dataHash {
            return cached.insight
        }

        return nil
    }

    func cache(_ insight: String, for key: String, dataHash: Int) {
        let calendar = Calendar.current
        let now = Date()
        let cached = CachedInsight(
            insight: insight,
            hour: calendar.component(.hour, from: now),
            day: calendar.component(.day, from: now),
            dataHash: dataHash,
            timestamp: now
        )

        if let data = try? JSONEncoder().encode(cached) {
            defaults.set(data, forKey: cacheKeyPrefix + key)
        }
    }

    func clearAll() {
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(cacheKeyPrefix) }
        keys.forEach { defaults.removeObject(forKey: $0) }
    }
}

final class GeminiService {
    static let shared = GeminiService()

    private let model: GenerativeModel
    private let visionModel: GenerativeModel
    private let cache = AIInsightCache.shared

    init(apiKey: String = APIConfig.geminiAPIKey) {
        self.model = GenerativeModel(
            name: "gemini-3-preview",
            apiKey: apiKey,
            generationConfig: GenerationConfig(
                temperature: 0.7,
                maxOutputTokens: 1024
            )
        )
        self.visionModel = GenerativeModel(
            name: "gemini-2.0-flash",
            apiKey: apiKey,
            generationConfig: GenerationConfig(
                temperature: 0.3,
                maxOutputTokens: 4096
            )
        )
    }

    /// Clear all cached AI insights
    func clearCache() {
        cache.clearAll()
    }

    // MARK: - Daily Summary with Goals & Comparison

    func generateDailySummary(
        sleep: SleepData?,
        activity: ActivityData?,
        heart: HeartData?,
        extendedContext: ExtendedHealthContext? = nil
    ) async throws -> AIInsight {
        // Check if we have any data at all
        guard sleep != nil || activity != nil || heart != nil else {
            return AIInsight(
                type: .dailySummary,
                title: "Daily Summary",
                content: "No health data available for today yet. Make sure HealthKit permissions are enabled and your device is syncing data. Try wearing your Apple Watch or logging some activity to see insights here.",
                metrics: [],
                priority: .low
            )
        }

        var prompt = buildDailySummaryPrompt(sleep: sleep, activity: activity, heart: heart)

        // Add extended context if available
        if let context = extendedContext {
            prompt += "\n\nBACKGROUND DATA (use naturally without explicitly mentioning you have this data):\n"
            prompt += context.description
        }
        let response = try await model.generateContent(prompt)

        guard let text = response.text else {
            throw GeminiError.noResponse
        }

        return AIInsight(
            type: .dailySummary,
            title: "Daily Summary",
            content: text,
            metrics: buildMetricsList(sleep: sleep, activity: activity, heart: heart),
            priority: .normal
        )
    }

    /// Generates a complete daily overview with comparison to yesterday and personal goals
    func generateDailyOverview(
        today: DailyHealthData,
        yesterday: DailyHealthData?,
        goals: HealthGoals,
        userProfile: UserHealthProfile? = nil,
        selectedDate: Date = Date()
    ) async throws -> String {
        // Create data hash for cache
        let dataHash = createDailyOverviewHash(today: today, yesterday: yesterday, selectedDate: selectedDate)

        // Use date string in cache key for historical views
        let calendar = Calendar.current
        let dateKey = calendar.isDateInToday(selectedDate) ? "today" : "\(calendar.component(.day, from: selectedDate))"
        let cacheKey = "daily_overview_\(dateKey)"

        // Check cache
        if let cachedInsight = cache.getCached(for: cacheKey, dataHash: dataHash) {
            return cachedInsight
        }

        let prompt = buildDailyOverviewPrompt(today: today, yesterday: yesterday, goals: goals, userProfile: userProfile, selectedDate: selectedDate)
        let response = try await model.generateContent(prompt)
        let insight = response.text ?? "Could not generate summary."

        // Cache the result
        cache.cache(insight, for: cacheKey, dataHash: dataHash)

        return insight
    }

    private func createDailyOverviewHash(today: DailyHealthData, yesterday: DailyHealthData?, selectedDate: Date) -> Int {
        var hasher = Hasher()
        // Hash today's data
        if let sleep = today.sleep {
            hasher.combine(Int(sleep.totalHours * 100))
        }
        hasher.combine(today.activity.steps)
        hasher.combine(today.activity.exerciseMinutes)
        hasher.combine(Int(today.heart.restingHeartRate))
        if let hrv = today.heart.hrv {
            hasher.combine(Int(hrv))
        }
        // Hash yesterday's data
        if let yday = yesterday {
            if let sleep = yday.sleep {
                hasher.combine(Int(sleep.totalHours * 100))
            }
            hasher.combine(yday.activity.steps)
        }
        // Hash date
        hasher.combine(Calendar.current.component(.day, from: selectedDate))
        return hasher.finalize()
    }

    /// Generates a summary for a specific metric
    func generateMetricInsight(
        metric: MetricType,
        todayValue: Double,
        yesterdayValue: Double?,
        weeklyAverage: Double?,
        goal: Double?,
        unit: String
    ) async throws -> String {
        // Create data hash
        var hasher = Hasher()
        hasher.combine(metric.rawValue)
        hasher.combine(Int(todayValue * 100))
        if let yesterday = yesterdayValue { hasher.combine(Int(yesterday * 100)) }
        if let avg = weeklyAverage { hasher.combine(Int(avg * 100)) }
        let dataHash = hasher.finalize()

        // Check cache
        let cacheKey = "metric_\(metric.rawValue)"
        if let cachedInsight = cache.getCached(for: cacheKey, dataHash: dataHash) {
            return cachedInsight
        }

        let prompt = buildMetricInsightPrompt(
            metric: metric,
            todayValue: todayValue,
            yesterdayValue: yesterdayValue,
            weeklyAverage: weeklyAverage,
            goal: goal,
            unit: unit
        )
        let response = try await model.generateContent(prompt)
        let insight = response.text ?? "Could not generate insight."

        // Cache the result
        cache.cache(insight, for: cacheKey, dataHash: dataHash)

        return insight
    }

    /// Generates a detailed sleep insight including sleep stages (REM, deep, light)
    func generateSleepInsight(
        sleepData: SleepData,
        yesterdaySleep: SleepData?,
        weeklyAverageSleep: Double?,
        goal: Double
    ) async throws -> String {
        // Create data hash from relevant values
        let dataHash = createSleepDataHash(sleepData: sleepData, yesterdaySleep: yesterdaySleep, weeklyAverage: weeklyAverageSleep)

        // Check cache first
        if let cachedInsight = cache.getCached(for: "sleep_insight", dataHash: dataHash) {
            return cachedInsight
        }

        let prompt = buildDetailedSleepInsightPrompt(
            sleepData: sleepData,
            yesterdaySleep: yesterdaySleep,
            weeklyAverageSleep: weeklyAverageSleep,
            goal: goal
        )
        let response = try await model.generateContent(prompt)
        let insight = response.text ?? "Could not generate insight."

        // Cache the result
        cache.cache(insight, for: "sleep_insight", dataHash: dataHash)

        return insight
    }

    private func createSleepDataHash(sleepData: SleepData, yesterdaySleep: SleepData?, weeklyAverage: Double?) -> Int {
        var hasher = Hasher()
        hasher.combine(Int(sleepData.totalHours * 100))
        hasher.combine(Int(sleepData.deepSleep))
        hasher.combine(Int(sleepData.remSleep))
        if let yesterday = yesterdaySleep {
            hasher.combine(Int(yesterday.totalHours * 100))
        }
        if let avg = weeklyAverage {
            hasher.combine(Int(avg * 100))
        }
        return hasher.finalize()
    }

    private func buildDetailedSleepInsightPrompt(
        sleepData: SleepData,
        yesterdaySleep: SleepData?,
        weeklyAverageSleep: Double?,
        goal: Double
    ) -> String {
        let deepSleepMinutes = Int(sleepData.deepSleep / 60)
        let remSleepMinutes = Int(sleepData.remSleep / 60)
        let lightSleepMinutes = Int(sleepData.lightSleep / 60)
        let awakeMinutes = Int(sleepData.awake / 60)

        let deepPercent = sleepData.totalDuration > 0 ? Int((sleepData.deepSleep / sleepData.totalDuration) * 100) : 0
        let remPercent = sleepData.totalDuration > 0 ? Int((sleepData.remSleep / sleepData.totalDuration) * 100) : 0
        let lightPercent = sleepData.totalDuration > 0 ? Int((sleepData.lightSleep / sleepData.totalDuration) * 100) : 0

        var prompt = """
        You are a sleep expert. Provide a brief, personalized insight (2-3 sentences) about the user's sleep in English.
        Focus on sleep stages (deep sleep, REM) and give one specific tip.

        TONIGHT'S SLEEP:
        - Total sleep: \(String(format: "%.1f", sleepData.totalHours)) hours (goal: \(String(format: "%.0f", goal)) hours)
        - Deep sleep: \(deepSleepMinutes) min (\(deepPercent)%) - optimal is 15-20% for physical recovery
        - REM sleep: \(remSleepMinutes) min (\(remPercent)%) - optimal is 20-25% for mental recovery and memory
        - Light sleep: \(lightSleepMinutes) min (\(lightPercent)%)
        - Awake time: \(awakeMinutes) min
        - Quality: \(sleepData.quality.displayText)
        """

        if let yesterday = yesterdaySleep {
            let yesterdayDeepMin = Int(yesterday.deepSleep / 60)
            let yesterdayRemMin = Int(yesterday.remSleep / 60)
            prompt += """

            YESTERDAY:
            - Total: \(String(format: "%.1f", yesterday.totalHours)) hours
            - Deep sleep: \(yesterdayDeepMin) min
            - REM sleep: \(yesterdayRemMin) min
            """
        }

        if let avg = weeklyAverageSleep {
            prompt += "\n- Weekly average: \(String(format: "%.1f", avg)) hours"
        }

        prompt += """

        Assess the sleep quality based on deep sleep and REM percentages.
        If deep sleep is low (<15%), suggest tips to improve it (exercise, temperature, timing).
        If REM is low (<20%), suggest tips (consistent sleep schedule, avoid alcohol).
        Be brief and actionable.

        IMPORTANT RULES:
        - Do NOT use any markdown formatting like **bold**, *italic*, bullet points, or emojis. Write plain text only.
        - NEVER mention nutrition, diet, food, eating, meals, or any dietary advice. We do not have nutrition data.
        """

        return prompt
    }

    private func buildDailyOverviewPrompt(today: DailyHealthData, yesterday: DailyHealthData?, goals: HealthGoals, userProfile: UserHealthProfile? = nil, selectedDate: Date = Date()) -> String {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(selectedDate)

        // Format selected date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "EEEE, MMMM d"
        let selectedDateString = dateFormatter.string(from: selectedDate)

        var prompt: String

        if isToday {
            // Get current time for today's overview
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "HH:mm"
            let currentTime = formatter.string(from: Date())
            let hour = calendar.component(.hour, from: Date())

            var timeContext = ""
            if hour < 6 {
                timeContext = "It's early morning/night"
            } else if hour < 10 {
                timeContext = "It's morning"
            } else if hour < 12 {
                timeContext = "It's late morning"
            } else if hour < 14 {
                timeContext = "It's lunch time"
            } else if hour < 17 {
                timeContext = "It's afternoon"
            } else if hour < 20 {
                timeContext = "It's evening"
            } else {
                timeContext = "It's late evening"
            }

            prompt = """
            You are a personal health coach. Give a brief, encouraging daily overview in English (max 3 sentences).
            Focus on what's most important and provide one concrete tip.
            Consider the user's age and physical condition when giving advice.

            IMPORTANT - CURRENT TIME: \(currentTime) (\(timeContext))
            Adapt your tips to the time of day. Don't suggest activities that are better suited for other times.
            Example: Don't suggest "lunch walk" if it's evening. Don't suggest workouts if it's late at night.
            """
        } else {
            // Historical day - don't give forward-looking tips
            prompt = """
            You are a personal health coach. Give a brief summary of \(selectedDateString) in English (max 3 sentences).

            IMPORTANT: This is HISTORICAL DATA for \(selectedDateString), NOT today.
            - Talk about this day in the past tense ("you worked out", "you slept")
            - Do NOT give tips about what the user can do now or today
            - Do NOT give tips about lunch, evening, or future activities
            - Just summarize how the day went and any observations
            """
        }

        // Add user profile if available
        if let profile = userProfile {
            prompt += "\n\nUSER PROFILE:"
            if let name = profile.name, !name.isEmpty {
                let firstName = name.components(separatedBy: " ").first ?? name
                prompt += "\n- Name: \(firstName) (use the name occasionally to make it personal, e.g., 'Great job \(firstName)!')"
            }
            if let age = profile.age {
                prompt += "\n- Age: \(age) years"
                if age < 30 {
                    prompt += " (young adult - can handle higher intensity)"
                } else if age < 50 {
                    prompt += " (middle-aged - balanced approach)"
                } else {
                    prompt += " (older adult - prioritize recovery)"
                }
            }
            if let height = profile.heightCm, let weight = profile.weightKg {
                prompt += "\n- Height: \(Int(height)) cm, Weight: \(String(format: "%.1f", weight)) kg"
                if let bmi = profile.bmi {
                    prompt += ", BMI: \(String(format: "%.1f", bmi))"
                }
            }
            if let bf = profile.bodyFatPercentage {
                prompt += "\n- Body Fat: \(String(format: "%.1f", bf))%"
            }
            if let vo2 = profile.vo2Max {
                prompt += "\n- VO2 Max: \(String(format: "%.1f", vo2)) ml/kg/min"
                if vo2 >= 50 {
                    prompt += " (excellent fitness)"
                } else if vo2 >= 40 {
                    prompt += " (good fitness)"
                } else if vo2 >= 35 {
                    prompt += " (average fitness)"
                } else {
                    prompt += " (needs improvement)"
                }
            }
        }

        prompt += "\n\nTODAY'S DATA:"

        // Sleep - treat 0 hours as "no data"
        if let sleep = today.sleep, sleep.totalHours > 0 {
            let sleepHours = sleep.totalHours
            let sleepGoalPercent = Int((sleepHours / goals.sleepHours) * 100)
            prompt += "\n- Sleep: \(String(format: "%.1f", sleepHours)) hours (goal: \(goals.sleepHours)h, \(sleepGoalPercent)%)"

            if let yesterdaySleep = yesterday?.sleep, yesterdaySleep.totalHours > 0 {
                let diff = sleepHours - yesterdaySleep.totalHours
                prompt += ", \(diff >= 0 ? "+" : "")\(String(format: "%.1f", diff))h compared to yesterday"
            }
        } else {
            prompt += "\n- Sleep: no data recorded"
        }

        // Steps - treat 0 as "no data"
        let steps = today.activity.steps
        if steps > 0 {
            let stepsGoalPercent = Int((Double(steps) / Double(goals.dailySteps)) * 100)
            prompt += "\n- Steps: \(steps) (goal: \(goals.dailySteps), \(stepsGoalPercent)%)"

            if let yesterdaySteps = yesterday?.activity.steps, yesterdaySteps > 0 {
                let diff = steps - yesterdaySteps
                prompt += ", \(diff >= 0 ? "+" : "")\(diff) compared to yesterday"
            }
        } else {
            prompt += "\n- Steps: no data recorded"
        }

        // Exercise - treat 0 as "no data"
        let exercise = today.activity.exerciseMinutes
        if exercise > 0 {
            let exerciseGoalPercent = Int((Double(exercise) / Double(goals.exerciseMinutes)) * 100)
            prompt += "\n- Exercise: \(exercise) min (goal: \(goals.exerciseMinutes) min, \(exerciseGoalPercent)%)"
        } else {
            prompt += "\n- Exercise: no activity recorded"
        }

        // Calories - treat 0 as "no data"
        let calories = Int(today.activity.activeCalories)
        if calories > 0 {
            let caloriesGoalPercent = Int((Double(calories) / Double(goals.activeCalories)) * 100)
            prompt += "\n- Calories: \(calories) kcal (goal: \(goals.activeCalories), \(caloriesGoalPercent)%)"
        } else {
            prompt += "\n- Calories: no data recorded"
        }

        // Heart - treat 0 as "no data"
        if let hrv = today.heart.hrv, hrv > 0 {
            prompt += "\n- HRV: \(Int(hrv)) ms"
            if let yesterdayHRV = yesterday?.heart.hrv, yesterdayHRV > 0 {
                let diff = hrv - yesterdayHRV
                prompt += " (\(diff >= 0 ? "+" : "")\(Int(diff)) ms)"
            }
        } else {
            prompt += "\n- HRV: no data recorded"
        }

        if today.heart.restingHeartRate > 0 {
            prompt += "\n- Resting Heart Rate: \(Int(today.heart.restingHeartRate)) bpm"
        } else {
            prompt += "\n- Resting Heart Rate: no data recorded"
        }

        prompt += """

        \nProvide a personal, motivating summary. Mention what went well and one concrete improvement tip.
        Keep it short and personal.

        IMPORTANT RULES:
        - Do NOT use any markdown formatting like **bold**, *italic*, bullet points, or emojis. Write plain text only.
        - NEVER mention nutrition, diet, food, eating, meals, or any dietary advice. We do not have nutrition data.
        """

        return prompt
    }

    private func buildMetricInsightPrompt(
        metric: MetricType,
        todayValue: Double,
        yesterdayValue: Double?,
        weeklyAverage: Double?,
        goal: Double?,
        unit: String
    ) -> String {
        let metricName: String
        let context: String

        switch metric {
        case .sleep:
            metricName = "sleep"
            context = "Optimal sleep is 7-9 hours. Deep sleep is important for physical recovery, REM for mental."
        case .activity:
            metricName = "activity"
            context = "WHO recommends 150 min moderate or 75 min intense exercise per week."
        case .heart:
            metricName = "heart health"
            context = "Lower resting heart rate and higher HRV indicate good cardiovascular health and recovery."
        default:
            metricName = "health"
            context = ""
        }

        var prompt = """
        You are a health expert. Provide a brief insight (2-3 sentences) about the user's \(metricName) in English.

        VALUES:
        - Today: \(String(format: "%.1f", todayValue)) \(unit)
        """

        if let yesterday = yesterdayValue {
            let diff = todayValue - yesterday
            prompt += "\n- Yesterday: \(String(format: "%.1f", yesterday)) \(unit) (change: \(diff >= 0 ? "+" : "")\(String(format: "%.1f", diff)))"
        }

        if let avg = weeklyAverage {
            prompt += "\n- Weekly average: \(String(format: "%.1f", avg)) \(unit)"
        }

        if let g = goal {
            let percent = Int((todayValue / g) * 100)
            prompt += "\n- Personal goal: \(String(format: "%.0f", g)) \(unit) (\(percent)% achieved)"
        }

        prompt += """

        CONTEXT: \(context)

        Provide a personal assessment. Include:
        1. How the value compares to goal/average
        2. One concrete tip for improvement or encouragement
        Keep it brief and motivating.

        IMPORTANT RULES:
        - Do NOT use any markdown formatting like **bold**, *italic*, bullet points, or emojis. Write plain text only.
        - NEVER mention nutrition, diet, food, eating, meals, or any dietary advice. We do not have nutrition data.
        """

        return prompt
    }

    // MARK: - Sleep Analysis

    func analyzeSleep(sleepData: [SleepData], extendedContext: ExtendedHealthContext? = nil) async throws -> AIInsight {
        var prompt = buildSleepAnalysisPrompt(sleepData: sleepData)

        // Add extended context if available
        if let context = extendedContext {
            prompt += "\n\nBACKGROUND DATA (use naturally without explicitly mentioning you have this data):\n"
            prompt += context.description
        }

        let response = try await model.generateContent(prompt)

        guard let text = response.text else {
            throw GeminiError.noResponse
        }

        return AIInsight(
            type: .sleepAnalysis,
            title: "Sleep Analysis",
            content: text,
            metrics: ["sleep"],
            priority: determinePriority(from: sleepData)
        )
    }

    // MARK: - Recovery Advice

    func generateRecoveryAdvice(
        sleep: SleepData?,
        heart: HeartData?,
        recentActivity: [ActivityData],
        extendedContext: ExtendedHealthContext? = nil
    ) async throws -> AIInsight {
        var prompt = buildRecoveryPrompt(sleep: sleep, heart: heart, recentActivity: recentActivity)

        // Add extended context if available
        if let context = extendedContext {
            prompt += "\n\nBACKGROUND DATA (use naturally without explicitly mentioning you have this data):\n"
            prompt += context.description
        }

        let response = try await model.generateContent(prompt)

        guard let text = response.text else {
            throw GeminiError.noResponse
        }

        return AIInsight(
            type: .recoveryAdvice,
            title: "Recovery Advice",
            content: text,
            metrics: ["recovery", "heart", "sleep"],
            priority: .normal
        )
    }

    // MARK: - Weekly Report

    func generateWeeklyReport(
        sleepData: [SleepData],
        activityData: [ActivityData],
        heartData: [HeartData]
    ) async throws -> AIInsight {
        let prompt = buildWeeklyReportPrompt(
            sleepData: sleepData,
            activityData: activityData,
            heartData: heartData
        )
        let response = try await model.generateContent(prompt)

        guard let text = response.text else {
            throw GeminiError.noResponse
        }

        return AIInsight(
            type: .weeklyReport,
            title: "Weekly Report",
            content: text,
            metrics: ["sleep", "activity", "heart"],
            priority: .normal
        )
    }

    // MARK: - Deep Analysis

    func generateDeepAnalysis(
        insightType: InsightType,
        sleepData: [SleepData],
        activityData: [ActivityData],
        heartData: [HeartData],
        userProfile: UserHealthProfile? = nil
    ) async throws -> AIInsight {
        let prompt = buildDeepAnalysisPrompt(
            insightType: insightType,
            sleepData: sleepData,
            activityData: activityData,
            heartData: heartData,
            userProfile: userProfile
        )

        let response = try await model.generateContent(prompt)

        guard let text = response.text else {
            throw GeminiError.noResponse
        }

        return AIInsight(
            type: insightType,
            title: "Deep Analysis: \(insightType.title)",
            content: text,
            metrics: ["sleep", "activity", "heart"],
            priority: .high
        )
    }

    private func buildDeepAnalysisPrompt(
        insightType: InsightType,
        sleepData: [SleepData],
        activityData: [ActivityData],
        heartData: [HeartData],
        userProfile: UserHealthProfile?
    ) -> String {
        var prompt = """
        You are an expert health analyst. Provide a comprehensive, detailed analysis based on the user's health data from the past month.
        Write in English. Be thorough but clear.

        """

        // Add user profile
        if let profile = userProfile {
            prompt += "USER PROFILE:\n"
            if let name = profile.name { prompt += "Name: \(name)\n" }
            if let age = profile.age { prompt += "Age: \(age) years\n" }
            if let height = profile.heightCm { prompt += "Height: \(Int(height)) cm\n" }
            if let weight = profile.weightKg { prompt += "Weight: \(String(format: "%.1f", weight)) kg\n" }
            if let bmi = profile.bmi { prompt += "BMI: \(String(format: "%.1f", bmi))\n" }
            prompt += "\n"
        }

        // Add sleep data summary
        if !sleepData.isEmpty {
            let avgSleep = sleepData.reduce(0) { $0 + $1.totalHours } / Double(sleepData.count)
            let avgDeep = sleepData.reduce(0) { $0 + $1.deepSleep } / Double(sleepData.count) / 60
            let avgRem = sleepData.reduce(0) { $0 + $1.remSleep } / Double(sleepData.count) / 60
            let goodNights = sleepData.filter { $0.quality == .good || $0.quality == .excellent }.count

            prompt += """
            SLEEP DATA (\(sleepData.count) nights):
            Average sleep: \(String(format: "%.1f", avgSleep)) hours/night
            Average deep sleep: \(Int(avgDeep)) min/night
            Average REM sleep: \(Int(avgRem)) min/night
            Good/Excellent nights: \(goodNights) of \(sleepData.count)
            Best night: \(String(format: "%.1f", sleepData.map { $0.totalHours }.max() ?? 0)) hours
            Worst night: \(String(format: "%.1f", sleepData.map { $0.totalHours }.min() ?? 0)) hours

            """
        }

        // Add activity data summary
        if !activityData.isEmpty {
            let avgSteps = activityData.reduce(0) { $0 + $1.steps } / activityData.count
            let avgCalories = activityData.reduce(0) { $0 + $1.activeCalories } / Double(activityData.count)
            let totalExercise = activityData.reduce(0) { $0 + $1.exerciseMinutes }
            let activeDays = activityData.filter { $0.exerciseMinutes > 0 }.count

            prompt += """
            ACTIVITY DATA (\(activityData.count) days):
            Average steps: \(avgSteps)/day
            Average active calories: \(Int(avgCalories)) kcal/day
            Total exercise: \(totalExercise) minutes
            Active days: \(activeDays) of \(activityData.count)
            Best step day: \(activityData.map { $0.steps }.max() ?? 0) steps
            Total distance: \(String(format: "%.1f", activityData.reduce(0) { $0 + $1.distance } / 1000)) km

            """
        }

        // Add heart data summary
        if !heartData.isEmpty {
            let avgRHR = heartData.reduce(0) { $0 + $1.restingHeartRate } / Double(heartData.count)
            let hrvValues = heartData.compactMap { $0.hrv }
            let avgHRV = hrvValues.isEmpty ? 0 : hrvValues.reduce(0, +) / Double(hrvValues.count)

            prompt += """
            HEART DATA (\(heartData.count) days):
            Average resting heart rate: \(Int(avgRHR)) bpm
            Lowest RHR: \(Int(heartData.map { $0.restingHeartRate }.min() ?? 0)) bpm
            Highest RHR: \(Int(heartData.map { $0.restingHeartRate }.max() ?? 0)) bpm
            Average HRV: \(Int(avgHRV)) ms

            """
        }

        // Focus area based on insight type
        let focusArea: String
        switch insightType {
        case .sleepAnalysis:
            focusArea = "Focus your analysis on sleep patterns, quality trends, and recovery."
        case .activityTrend:
            focusArea = "Focus your analysis on activity levels, exercise consistency, and fitness progress."
        case .heartHealth:
            focusArea = "Focus your analysis on cardiovascular health, HRV trends, and recovery indicators."
        case .recoveryAdvice:
            focusArea = "Focus your analysis on recovery status, training load balance, and rest recommendations."
        default:
            focusArea = "Provide a holistic analysis covering sleep, activity, and heart health."
        }

        prompt += """
        \(focusArea)

        Provide a comprehensive analysis including:
        1. Overall assessment of the data patterns
        2. Trends identified (improving, declining, stable)
        3. Correlations between different metrics
        4. Specific actionable recommendations
        5. Areas of concern if any
        6. Positive observations and encouragements

        Write 4-6 paragraphs with clear insights.

        IMPORTANT: Do NOT use any markdown formatting like **bold**, *italic*, bullet points, numbered lists, or emojis. Write plain flowing text only.
        """

        return prompt
    }

    // MARK: - Chat

    func chat(message: String, context: ExtendedHealthContext) async throws -> String {
        let prompt = """
        You are a concise health educator. The user is chatting with you about their health.
        You have access to their data below, but ONLY mention data that is directly relevant to their question.
        Keep answers short and conversational (2-4 sentences). Do not write a full report.

        AVAILABLE DATA:
        \(context.description)

        User: \(message)

        Answer the question directly. Reference specific numbers only when relevant to what they asked.

        IMPORTANT: Do NOT use any markdown formatting like **bold**, *italic*, bullet points, or emojis. Write plain text only.
        NEVER mention nutrition, diet, food, eating, meals, or any dietary advice.
        This is educational information only.
        """

        let selectedModel = GeminiModelSelection.current
        let response = try await selectedModel.useFlash ? visionModel.generateContent(prompt) : model.generateContent(prompt)
        return response.text ?? "Could not generate response."
    }

    // Legacy chat for backward compatibility
    func chat(message: String, context: HealthContext) async throws -> String {
        let extendedContext = ExtendedHealthContext(
            todaySleep: context.sleep,
            todayActivity: context.activity,
            todayHeart: context.heart,
            sleepHistory: [],
            activityHistory: [],
            heartHistory: []
        )
        return try await chat(message: message, context: extendedContext)
    }

    // MARK: - Health Document Parsing (Multimodal)

    func parseHealthDocument(data: Data, mimeType: String) async throws -> HealthCheckup {
        let prompt = """
        You are a medical lab report parser. Extract ALL lab values from this health checkup document.

        Return a JSON object with this exact structure:
        {
            "title": "Brief description of the report type",
            "provider": "Name of the healthcare provider/lab if visible, or null",
            "date": "YYYY-MM-DD if visible, otherwise null",
            "values": [
                {
                    "name": "Full name of the lab test (in English)",
                    "value": 5.2,
                    "unit": "mmol/L",
                    "referenceMin": 0.0,
                    "referenceMax": 5.0,
                    "category": "cholesterol"
                }
            ],
            "summary": "Brief plain text summary of the results (2-3 sentences)"
        }

        Valid categories: cholesterol, blood_sugar, liver, kidney, thyroid, blood_count, inflammation, vitamins, hormones, other

        If the document is in Swedish or another language, translate lab test names to English.
        Include reference ranges when visible on the document.
        IMPORTANT: Return ONLY valid JSON, no markdown, no code fences, no extra text.
        IMPORTANT: Do NOT use any markdown formatting in the summary.
        NEVER mention nutrition, diet, food, eating, meals, or any dietary advice in the summary.
        """

        let response = try await visionModel.generateContent(
            prompt,
            ModelContent.Part.data(mimetype: mimeType, data)
        )

        guard let text = response.text else {
            throw GeminiError.noResponse
        }

        // Clean response (strip code fences if present)
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if jsonString.hasPrefix("```") {
            let lines = jsonString.components(separatedBy: "\n")
            let filtered = lines.dropFirst().dropLast()
            jsonString = filtered.joined(separator: "\n")
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw HealthCheckupError.parseFailed
        }

        struct ParsedReport: Decodable {
            let title: String?
            let provider: String?
            let date: String?
            let values: [ParsedValue]
            let summary: String?
        }

        struct ParsedValue: Decodable {
            let name: String
            let value: Double
            let unit: String
            let referenceMin: Double?
            let referenceMax: Double?
            let category: String?
        }

        let parsed = try JSONDecoder().decode(ParsedReport.self, from: jsonData)

        let labValues = parsed.values.map { v in
            LabValue(
                name: v.name,
                value: v.value,
                unit: v.unit,
                referenceMin: v.referenceMin,
                referenceMax: v.referenceMax,
                category: LabCategory(rawValue: v.category ?? "other") ?? .other
            )
        }

        var checkupDate = Date()
        if let dateStr = parsed.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let d = formatter.date(from: dateStr) {
                checkupDate = d
            }
        }

        return HealthCheckup(
            date: checkupDate,
            title: parsed.title ?? "Health Checkup",
            provider: parsed.provider,
            labValues: labValues,
            aiSummary: parsed.summary
        )
    }

    // MARK: - Lab Value Insight

    func generateLabValueInsight(labValue: LabValue) async throws -> String {
        // Create data hash from name + value
        var hasher = Hasher()
        hasher.combine(labValue.name)
        hasher.combine(Int(labValue.value * 100))
        let dataHash = hasher.finalize()

        let cacheKey = "lab_\(labValue.name.lowercased().replacingOccurrences(of: " ", with: "_"))"

        // Check cache
        if let cachedInsight = cache.getCached(for: cacheKey, dataHash: dataHash) {
            return cachedInsight
        }

        var refContext = ""
        if let min = labValue.referenceMin, let max = labValue.referenceMax {
            refContext = "Reference range: \(String(format: "%.1f", min)) - \(String(format: "%.1f", max)) \(labValue.unit). "
        }

        let prompt = """
        You are a health educator explaining lab results to a user in simple terms.

        Lab test: \(labValue.name)
        Result: \(labValue.formattedValue)
        Status: \(labValue.statusText)
        \(refContext)

        In max 80 words, provide:
        1. What this test measures and why it matters (one sentence)
        2. How this specific result looks (one to two sentences)

        Write in English. Be informative and reassuring.

        IMPORTANT RULES:
        - Do NOT use any markdown formatting like **bold**, *italic*, bullet points, or emojis. Write plain text only.
        - NEVER mention nutrition, diet, food, eating, meals, or any dietary advice.
        - This is educational information only, not medical advice.
        """

        let selectedModel = GeminiModelSelection.current
        let response = try await selectedModel.useFlash ? visionModel.generateContent(prompt) : model.generateContent(prompt)
        let insight = response.text ?? "Could not generate insight."

        // Cache the result
        cache.cache(insight, for: cacheKey, dataHash: dataHash)

        return insight
    }

    // MARK: - Generic Content Generation

    func generateContent(prompt: String) async throws -> String {
        let selectedModel = GeminiModelSelection.current
        let response = try await selectedModel.useFlash ? visionModel.generateContent(prompt) : model.generateContent(prompt)
        return response.text ?? "Could not generate content."
    }

    // MARK: - Private Helpers

    private func buildDailySummaryPrompt(sleep: SleepData?, activity: ActivityData?, heart: HeartData?) -> String {
        var dataDescription = "Analyze the following health data and provide a brief daily summary in English:\n\n"

        if let sleep = sleep {
            dataDescription += """
            SLEEP:
            - Total sleep: \(sleep.formattedDuration)
            - Deep sleep: \(Int(sleep.deepSleep / 60)) min
            - REM sleep: \(Int(sleep.remSleep / 60)) min
            - Quality: \(sleep.quality.displayText)

            """
        }

        if let activity = activity {
            dataDescription += """
            ACTIVITY:
            - Steps: \(activity.steps)
            - Active calories: \(Int(activity.activeCalories)) kcal
            - Distance: \(activity.formattedDistance)
            - Exercise minutes: \(activity.exerciseMinutes) min

            """
        }

        if let heart = heart {
            dataDescription += """
            HEART:
            - Resting heart rate: \(Int(heart.restingHeartRate)) bpm
            - HRV: \(heart.hrv.map { "\(Int($0)) ms" } ?? "Not available")

            """
        }

        dataDescription += """

        Provide a brief, encouraging summary (2-3 sentences) of the day.
        Include one concrete tip for improvement if something can be improved.

        IMPORTANT: Do NOT use any markdown formatting like **bold**, *italic*, or bullet points. Write plain text only.
        """

        return dataDescription
    }

    private func buildSleepAnalysisPrompt(sleepData: [SleepData]) -> String {
        var prompt = "Analyze the following sleep data from recent days and provide insights in English:\n\n"

        for (index, sleep) in sleepData.enumerated() {
            prompt += """
            Day \(index + 1):
            - Total sleep: \(sleep.formattedDuration)
            - Deep sleep: \(Int(sleep.deepSleep / 60)) min (\(Int((sleep.deepSleep / sleep.totalDuration) * 100))%)
            - REM sleep: \(Int(sleep.remSleep / 60)) min (\(Int((sleep.remSleep / sleep.totalDuration) * 100))%)
            - Quality: \(sleep.quality.displayText)

            """
        }

        prompt += """

        Identify patterns and provide 2-3 concrete tips for better sleep.
        Keep the answer brief and actionable.

        IMPORTANT RULES:
        - Do NOT use any markdown formatting like **bold**, *italic*, bullet points, or emojis. Write plain text only.
        - NEVER mention nutrition, diet, food, eating, meals, or any dietary advice. We do not have nutrition data.
        """

        return prompt
    }

    private func buildRecoveryPrompt(sleep: SleepData?, heart: HeartData?, recentActivity: [ActivityData]) -> String {
        var prompt = "Based on the following data, assess recovery status and provide advice in English:\n\n"

        if let sleep = sleep {
            prompt += "Sleep: \(sleep.formattedDuration), quality: \(sleep.quality.displayText)\n"
        }

        if let heart = heart {
            prompt += "Resting heart rate: \(Int(heart.restingHeartRate)) bpm\n"
            if let hrv = heart.hrv {
                prompt += "HRV: \(Int(hrv)) ms (\(heart.hrvStatus.displayText))\n"
            }
        }

        let totalActivity = recentActivity.reduce(0) { $0 + $1.exerciseMinutes }
        prompt += "Recent training: \(totalActivity) minutes total\n"

        prompt += """

        Provide a brief assessment of recovery status and recommendation:
        Is it a good day for intense training, or should the user focus on recovery?
        Keep the answer brief (2-3 sentences).

        IMPORTANT RULES:
        - Do NOT use any markdown formatting like **bold**, *italic*, bullet points, or emojis. Write plain text only.
        - NEVER mention nutrition, diet, food, eating, meals, or any dietary advice. We do not have nutrition data.
        """

        return prompt
    }

    private func buildWeeklyReportPrompt(sleepData: [SleepData], activityData: [ActivityData], heartData: [HeartData]) -> String {
        let avgSleep = sleepData.isEmpty ? 0 : sleepData.reduce(0) { $0 + $1.totalHours } / Double(sleepData.count)
        let avgSteps = activityData.isEmpty ? 0 : activityData.reduce(0) { $0 + $1.steps } / activityData.count
        let totalExercise = activityData.reduce(0) { $0 + $1.exerciseMinutes }
        let avgHR = heartData.isEmpty ? 0 : heartData.reduce(0) { $0 + $1.restingHeartRate } / Double(heartData.count)

        return """
        Create a weekly report in English based on:

        SLEEP (weekly average):
        Average: \(String(format: "%.1f", avgSleep)) hours/night
        Number of nights with data: \(sleepData.count)

        ACTIVITY (week):
        Average steps: \(avgSteps)/day
        Total exercise: \(totalExercise) minutes

        HEART:
        Average resting heart rate: \(Int(avgHR)) bpm

        Provide a summary covering: week's highlights, one area to improve, and goals for next week.
        Keep it brief and motivating.

        IMPORTANT RULES:
        - Do NOT use any markdown formatting like **bold**, *italic*, bullet points, numbered lists, or emojis. Write plain flowing text only.
        - NEVER mention nutrition, diet, food, eating, meals, or any dietary advice. We do not have nutrition data.
        """
    }

    private func buildMetricsList(sleep: SleepData?, activity: ActivityData?, heart: HeartData?) -> [String] {
        var metrics: [String] = []
        if sleep != nil { metrics.append("sleep") }
        if activity != nil { metrics.append("activity") }
        if heart != nil { metrics.append("heart") }
        return metrics
    }

    private func determinePriority(from sleepData: [SleepData]) -> InsightPriority {
        let poorNights = sleepData.filter { $0.quality == .poor || $0.quality == .fair }.count
        if poorNights >= 3 {
            return .high
        } else if poorNights >= 1 {
            return .normal
        }
        return .low
    }
}

struct HealthContext {
    let sleep: SleepData?
    let activity: ActivityData?
    let heart: HeartData?

    var description: String {
        var desc = ""
        if let sleep = sleep {
            desc += "Sleep: \(sleep.formattedDuration)\n"
        }
        if let activity = activity {
            desc += "Steps: \(activity.steps), Calories: \(Int(activity.activeCalories))\n"
        }
        if let heart = heart {
            desc += "Resting heart rate: \(Int(heart.restingHeartRate)) bpm\n"
        }
        return desc.isEmpty ? "No data available" : desc
    }
}

/// Extended health context with historical data for comprehensive analysis
struct ExtendedHealthContext {
    let todaySleep: SleepData?
    let todayActivity: ActivityData?
    let todayHeart: HeartData?
    let sleepHistory: [SleepData]
    let activityHistory: [ActivityData]
    let heartHistory: [HeartData]
    // Body measurements
    let bodyMeasurements: [BodyMeasurement]
    // GLP-1 treatment data
    let glp1Treatment: GLP1Treatment?
    let glp1Injections: [MedicationLog]
    // User profile
    let userProfile: UserHealthProfile?
    // Health checkups (lab results)
    let healthCheckups: [HealthCheckup]

    init(
        todaySleep: SleepData? = nil,
        todayActivity: ActivityData? = nil,
        todayHeart: HeartData? = nil,
        sleepHistory: [SleepData] = [],
        activityHistory: [ActivityData] = [],
        heartHistory: [HeartData] = [],
        bodyMeasurements: [BodyMeasurement] = [],
        glp1Treatment: GLP1Treatment? = nil,
        glp1Injections: [MedicationLog] = [],
        userProfile: UserHealthProfile? = nil,
        healthCheckups: [HealthCheckup] = []
    ) {
        self.todaySleep = todaySleep
        self.todayActivity = todayActivity
        self.todayHeart = todayHeart
        self.sleepHistory = sleepHistory
        self.activityHistory = activityHistory
        self.heartHistory = heartHistory
        self.bodyMeasurements = bodyMeasurements
        self.glp1Treatment = glp1Treatment
        self.glp1Injections = glp1Injections
        self.userProfile = userProfile
        self.healthCheckups = healthCheckups
    }

    var description: String {
        var desc = ""

        // User profile
        if let profile = userProfile {
            if let name = profile.name {
                desc += "User: \(name)\n"
            }
            if let age = profile.age {
                desc += "Age: \(age) years\n"
            }
            if let height = profile.heightCm {
                desc += "Height: \(Int(height)) cm\n"
            }
        }

        // Today's data
        desc += "\nTODAY:\n"
        if let sleep = todaySleep {
            desc += "Sleep: \(sleep.formattedDuration), Quality: \(sleep.quality.displayText)\n"
        }
        if let activity = todayActivity {
            desc += "Steps: \(activity.steps), Calories: \(Int(activity.activeCalories)), Exercise: \(activity.exerciseMinutes) min\n"
        }
        if let heart = todayHeart {
            desc += "Resting HR: \(Int(heart.restingHeartRate)) bpm"
            if let hrv = heart.hrv {
                desc += ", HRV: \(Int(hrv)) ms"
            }
            desc += "\n"
        }

        // Body measurements
        if !bodyMeasurements.isEmpty {
            desc += "\nBODY MEASUREMENTS (last 30 days):\n"
            let weightMeasurements = bodyMeasurements.compactMap { $0.weight }
            let waistMeasurements = bodyMeasurements.compactMap { $0.waistCircumference }

            if let latestWeight = bodyMeasurements.first?.weight {
                desc += "Current weight: \(String(format: "%.1f", latestWeight)) kg\n"
            }
            if weightMeasurements.count >= 2 {
                let firstWeight = weightMeasurements.last!
                let lastWeight = weightMeasurements.first!
                let change = lastWeight - firstWeight
                desc += "Weight change: \(change >= 0 ? "+" : "")\(String(format: "%.1f", change)) kg\n"
            }
            if let latestWaist = bodyMeasurements.first?.waistCircumference {
                desc += "Current waist: \(String(format: "%.0f", latestWaist)) cm\n"
            }
            if waistMeasurements.count >= 2 {
                let firstWaist = waistMeasurements.last!
                let lastWaist = waistMeasurements.first!
                let change = lastWaist - firstWaist
                desc += "Waist change: \(change >= 0 ? "+" : "")\(String(format: "%.1f", change)) cm\n"
            }
        }

        // GLP-1 treatment
        if let treatment = glp1Treatment {
            desc += "\nGLP-1 MEDICATION:\n"
            desc += "Medication: \(treatment.medication.displayName)\n"
            desc += "Current dose: \(treatment.currentDose) \(treatment.medication.unit)\n"
            desc += "Weeks on treatment: \(treatment.weeksOnTreatment)\n"
            desc += "Start weight: \(String(format: "%.1f", treatment.startWeight)) kg\n"
            if let target = treatment.targetWeight {
                desc += "Target weight: \(String(format: "%.1f", target)) kg\n"
            }
            if treatment.isReadyForDoseIncrease, let nextDose = treatment.nextDose {
                desc += "Ready for dose increase to \(nextDose) \(treatment.medication.unit)\n"
            }
        }

        if !glp1Injections.isEmpty {
            desc += "\nRECENT INJECTIONS (\(glp1Injections.count)):\n"
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            for injection in glp1Injections.prefix(5) {
                let dateStr = formatter.string(from: injection.date)
                desc += "- \(dateStr): \(injection.dose) mg"
                if injection.skipped {
                    desc += " (SKIPPED: \(injection.skipReason ?? "no reason"))"
                }
                desc += "\n"
            }
        }

        // Historical summaries
        if !sleepHistory.isEmpty {
            let avgSleep = sleepHistory.reduce(0) { $0 + $1.totalHours } / Double(sleepHistory.count)
            let goodNights = sleepHistory.filter { $0.quality == .good || $0.quality == .excellent }.count
            desc += "\nSLEEP HISTORY (\(sleepHistory.count) nights):\n"
            desc += "Average: \(String(format: "%.1f", avgSleep)) hours/night\n"
            desc += "Good nights: \(goodNights) of \(sleepHistory.count)\n"
        }

        if !activityHistory.isEmpty {
            let avgSteps = activityHistory.reduce(0) { $0 + $1.steps } / activityHistory.count
            let totalExercise = activityHistory.reduce(0) { $0 + $1.exerciseMinutes }
            desc += "\nACTIVITY HISTORY (\(activityHistory.count) days):\n"
            desc += "Average steps: \(avgSteps)/day\n"
            desc += "Total exercise: \(totalExercise) minutes\n"
        }

        if !heartHistory.isEmpty {
            let avgRHR = heartHistory.reduce(0) { $0 + $1.restingHeartRate } / Double(heartHistory.count)
            let hrvValues = heartHistory.compactMap { $0.hrv }
            desc += "\nHEART HISTORY (\(heartHistory.count) days):\n"
            desc += "Average RHR: \(Int(avgRHR)) bpm\n"
            if !hrvValues.isEmpty {
                let avgHRV = hrvValues.reduce(0, +) / Double(hrvValues.count)
                desc += "Average HRV: \(Int(avgHRV)) ms\n"
            }
        }

        // Lab results / health checkups
        if !healthCheckups.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"

            desc += "\nLAB RESULTS:\n"
            if let latest = healthCheckups.first {
                desc += "Latest checkup: \(formatter.string(from: latest.date))"
                if let provider = latest.provider {
                    desc += " (\(provider))"
                }
                desc += "\n"

                let outOfRange = latest.labValues.filter(\.isOutOfRange)
                if !outOfRange.isEmpty {
                    desc += "Out of range values:\n"
                    for val in outOfRange {
                        desc += "- \(val.name): \(val.formattedValue) [\(val.statusText)]\n"
                    }
                }

                for val in latest.labValues.prefix(15) {
                    if !val.isOutOfRange {
                        desc += "- \(val.name): \(val.formattedValue)\n"
                    }
                }

                if let summary = latest.aiSummary {
                    desc += "Summary: \(summary)\n"
                }
            }

            if healthCheckups.count > 1 {
                desc += "Previous checkups available: \(healthCheckups.count - 1)\n"
            }
        }

        return desc.isEmpty ? "No data available" : desc
    }
}

/// User's profile for personalized AI analyses
struct UserHealthProfile {
    let name: String?
    let age: Int?
    let heightCm: Double?
    let weightKg: Double?
    let bodyFatPercentage: Double?
    let vo2Max: Double?
    let leanBodyMass: Double?

    var bmi: Double? {
        guard let height = heightCm, let weight = weightKg, height > 0 else { return nil }
        let heightM = height / 100
        return weight / (heightM * heightM)
    }

    var description: String {
        var desc = ""
        if let age = age { desc += "Age: \(age) years\n" }
        if let height = heightCm { desc += "Height: \(Int(height)) cm\n" }
        if let weight = weightKg { desc += "Weight: \(String(format: "%.1f", weight)) kg\n" }
        if let bmi = bmi { desc += "BMI: \(String(format: "%.1f", bmi))\n" }
        if let bf = bodyFatPercentage { desc += "Body fat: \(String(format: "%.1f", bf))%\n" }
        if let vo2 = vo2Max { desc += "VO2 Max: \(String(format: "%.1f", vo2)) ml/kg/min\n" }
        return desc.isEmpty ? "No profile data available" : desc
    }
}

// MARK: - Model Selection

enum GeminiModelSelection: String, CaseIterable {
    case flash = "gemini-2.0-flash"
    case preview = "gemini-3-preview"

    var displayName: String {
        switch self {
        case .flash: return "Gemini 2.0 Flash"
        case .preview: return "Gemini 3 Preview"
        }
    }

    var useFlash: Bool { self == .flash }

    private static let defaultsKey = "gemini_model_selection"

    static var current: GeminiModelSelection {
        get {
            guard let raw = UserDefaults.standard.string(forKey: defaultsKey),
                  let model = GeminiModelSelection(rawValue: raw) else {
                return .flash
            }
            return model
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
        }
    }
}

enum GeminiError: LocalizedError {
    case noResponse
    case quotaExceeded
    case invalidRequest
    case invalidAPIKey

    var errorDescription: String? {
        switch self {
        case .noResponse: return "Could not get response from AI"
        case .quotaExceeded: return "AI quota has been exceeded"
        case .invalidRequest: return "Invalid request"
        case .invalidAPIKey: return "Invalid API key"
        }
    }
}
