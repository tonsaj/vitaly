import Foundation
import SwiftUI
import os.log

@Observable
final class DashboardViewModel {
    private let logger = Logger(subsystem: "com.perfectfools.vitaly", category: "Dashboard")
    // MARK: - Published State
    var sleepData: SleepData?
    var activityData: ActivityData?
    var heartData: HeartData?

    // Historisk data
    var yesterdayData: DailyHealthData?
    var weeklyData: WeeklyHealthData?

    // AI Sammanfattning
    var aiSummary: String?
    var isLoadingAI = false

    var isLoading = false
    var error: Error?
    var lastRefreshDate: Date?

    // MARK: - Date Navigation
    var selectedDate: Date = Date()

    // MARK: - Dependencies
    private let healthKitService: HealthKitService
    private let geminiService: GeminiService
    private var userGoals: HealthGoals = .defaultGoals
    private var userProfile: UserHealthProfile?

    // MARK: - Computed Properties
    var hasData: Bool {
        sleepData != nil || activityData != nil || heartData != nil
    }

    var todayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: selectedDate)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(selectedDate)
    }

    var canGoForward: Bool {
        !isToday
    }

    var canGoBack: Bool {
        // Allow going back up to 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return selectedDate > thirtyDaysAgo
    }

    var dateDisplayText: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            formatter.locale = Locale(identifier: "en_US")
            return formatter.string(from: selectedDate)
        }
    }

    var overallScore: Int {
        var total = 0
        var count = 0

        if let sleep = sleepData {
            total += sleep.quality.score
            count += 1
        }

        if let activity = activityData {
            total += activity.activityScore
            count += 1
        }

        if let heart = heartData {
            let hrvScore: Int = {
                switch heart.hrvStatus {
                case .excellent: return 90
                case .good: return 75
                case .fair: return 55
                case .low: return 30
                case .unknown: return 50
                }
            }()
            total += hrvScore
            count += 1
        }

        return count > 0 ? total / count : 0
    }

    var overallScoreText: String {
        switch overallScore {
        case 85...100: return "Excellent"
        case 70..<85: return "Very good"
        case 55..<70: return "Good"
        case 40..<55: return "Okay"
        default: return "Needs improvement"
        }
    }

    // MARK: - Weekly Trend Data (från riktig HealthKit-data)
    var weeklyTrendData: [DayTrendData] {
        guard let weekly = weeklyData else {
            // Fallback to demo
            let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            let scores = [72.0, 68.0, 78.0, 82.0, 75.0, 85.0, Double(overallScore)]
            return zip(days, scores).map { DayTrendData(dayName: $0, score: $1) }
        }

        // Beräkna poäng för varje dag baserat på riktig data
        let calendar = Calendar.current
        let today = Date()

        return (0..<7).reversed().map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            formatter.locale = Locale(identifier: "en_US")
            let dayName = formatter.string(from: date)

            let index = 6 - dayOffset
            guard index < weekly.activityData.count else {
                return DayTrendData(dayName: dayName, score: 0)
            }

            // Beräkna dagligt score
            var score = 0.0
            var count = 0

            if let sleep = weekly.sleepData[safe: index] {
                score += Double(sleep?.quality.score ?? 50)
                count += 1
            }

            let activity = weekly.activityData[index]
            score += Double(activity.activityScore)
            count += 1

            if let hrv = weekly.heartData[safe: index]?.hrv {
                let hrvScore = hrv >= 50 ? 85.0 : hrv >= 35 ? 65.0 : 45.0
                score += hrvScore
                count += 1
            }

            return DayTrendData(dayName: dayName, score: count > 0 ? score / Double(count) : 50)
        }
    }

    var averageSleepHours: Double {
        if let weekly = weeklyData {
            return weekly.averageSleepHours
        }
        guard let sleep = sleepData else { return 0 }
        return sleep.totalHours
    }

    var averageSteps: Int {
        if let weekly = weeklyData {
            return weekly.averageSteps
        }
        guard let activity = activityData else { return 0 }
        return activity.steps
    }

    var averageHRV: Double {
        if let weekly = weeklyData {
            return weekly.averageHRV
        }
        guard let heart = heartData, let hrv = heart.hrv else { return 0 }
        return hrv
    }

    // MARK: - Jämförelse med igår
    var yesterdaySleepHours: Double {
        yesterdayData?.sleep?.totalHours ?? 0
    }

    var yesterdaySteps: Int {
        yesterdayData?.activity.steps ?? 0
    }

    var yesterdayHRV: Double {
        yesterdayData?.heart.hrv ?? 0
    }

    var sleepChange: Double {
        guard let today = sleepData?.totalHours else { return 0 }
        return today - yesterdaySleepHours
    }

    var stepsChange: Int {
        guard let today = activityData?.steps else { return 0 }
        return today - yesterdaySteps
    }

    var hrvChange: Double {
        guard let today = heartData?.hrv else { return 0 }
        return today - yesterdayHRV
    }

    // MARK: - Init
    init(healthKitService: HealthKitService = HealthKitService(), geminiService: GeminiService = GeminiService()) {
        self.healthKitService = healthKitService
        self.geminiService = geminiService
    }

    // MARK: - Update User Settings
    func updateGoals(_ goals: HealthGoals) {
        self.userGoals = goals
    }

    func updateUserProfile(name: String? = nil, age: Int?, heightCm: Double?, weightKg: Double?, bodyFatPercentage: Double? = nil, vo2Max: Double? = nil) {
        self.userProfile = UserHealthProfile(
            name: name,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            bodyFatPercentage: bodyFatPercentage,
            vo2Max: vo2Max,
            leanBodyMass: nil
        )
    }

    // MARK: - Date Navigation
    @MainActor
    func goToPreviousDay() {
        guard canGoBack else { return }
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        Task {
            await loadDataForSelectedDate()
        }
    }

    @MainActor
    func goToNextDay() {
        guard canGoForward else { return }
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        Task {
            await loadDataForSelectedDate()
        }
    }

    @MainActor
    func goToToday() {
        selectedDate = Date()
        Task {
            await loadDataForSelectedDate()
        }
    }

    // MARK: - Data Loading
    @MainActor
    func loadTodayData() async {
        await loadDataForSelectedDate()
    }

    @MainActor
    func loadDataForSelectedDate() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Request HealthKit authorization if not determined
            let authStatus = healthKitService.checkAuthorizationStatus()
            if authStatus == .notDetermined {
                try await healthKitService.requestAuthorization()
            }

            // Hämta data för valt datum
            async let sleep = healthKitService.fetchSleepData(for: selectedDate)
            async let activity = healthKitService.fetchActivityData(for: selectedDate)
            async let heart = healthKitService.fetchHeartData(for: selectedDate)

            // Hämta historisk data
            async let yesterday = healthKitService.fetchYesterdayData()
            async let weekly = healthKitService.fetchWeeklyData()

            self.sleepData = try await sleep
            self.activityData = try await activity
            self.heartData = try await heart
            self.yesterdayData = try await yesterday
            self.weeklyData = try await weekly

            lastRefreshDate = Date()

            // Ladda AI-sammanfattning i bakgrunden
            await loadAISummary()
        } catch {
            // Ignorera "no data" fel - visa bara "--" i UI
            if !error.localizedDescription.contains("No data") {
                logger.error("❌ Dashboard fel: \(error.localizedDescription)")
                self.error = error
            }
        }

        isLoading = false
    }

    @MainActor
    func loadAISummary() async {
        guard hasData else { return }
        guard !isLoadingAI else { return }

        isLoadingAI = true

        do {
            // Create today's data object - use actual data, don't fill with zeros
            let todayData = DailyHealthData(
                date: selectedDate,
                sleep: sleepData,  // Keep as is - can be nil
                activity: activityData ?? ActivityData(
                    id: UUID().uuidString,
                    date: selectedDate,
                    steps: 0,
                    activeCalories: 0,
                    totalCalories: 0,
                    distance: 0,
                    exerciseMinutes: 0,
                    standHours: 0,
                    workouts: []
                ),
                heart: heartData ?? HeartData(
                    id: UUID().uuidString,
                    date: selectedDate,
                    restingHeartRate: 0,
                    averageHeartRate: 0,
                    maxHeartRate: 0,
                    minHeartRate: 0,
                    hrv: nil,
                    heartRateZones: []
                )
            )

            aiSummary = try await geminiService.generateDailyOverview(
                today: todayData,
                yesterday: yesterdayData,
                goals: userGoals,
                userProfile: userProfile,
                selectedDate: selectedDate
            )
        } catch {
            logger.error("AI summary error: \(error.localizedDescription)")
            aiSummary = nil
        }

        isLoadingAI = false
    }

    @MainActor
    func refresh() async {
        await loadTodayData()
    }
}

// MARK: - Safe Array Access
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
