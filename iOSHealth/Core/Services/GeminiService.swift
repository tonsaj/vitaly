import Foundation
import GoogleGenerativeAI

final class GeminiService {
    private let model: GenerativeModel

    init(apiKey: String = APIConfig.geminiAPIKey) {
        self.model = GenerativeModel(
            name: "gemini-2.0-flash",
            apiKey: apiKey,
            generationConfig: GenerationConfig(
                temperature: 0.7,
                maxOutputTokens: 1024
            )
        )
    }

    // MARK: - Daily Summary

    func generateDailySummary(
        sleep: SleepData?,
        activity: ActivityData?,
        heart: HeartData?
    ) async throws -> AIInsight {
        let prompt = buildDailySummaryPrompt(sleep: sleep, activity: activity, heart: heart)
        let response = try await model.generateContent(prompt)

        guard let text = response.text else {
            throw GeminiError.noResponse
        }

        return AIInsight(
            type: .dailySummary,
            title: "Daglig sammanfattning",
            content: text,
            metrics: buildMetricsList(sleep: sleep, activity: activity, heart: heart),
            priority: .normal
        )
    }

    // MARK: - Sleep Analysis

    func analyzeSleep(sleepData: [SleepData]) async throws -> AIInsight {
        let prompt = buildSleepAnalysisPrompt(sleepData: sleepData)
        let response = try await model.generateContent(prompt)

        guard let text = response.text else {
            throw GeminiError.noResponse
        }

        return AIInsight(
            type: .sleepAnalysis,
            title: "Sömnanalys",
            content: text,
            metrics: ["sleep"],
            priority: determinePriority(from: sleepData)
        )
    }

    // MARK: - Recovery Advice

    func generateRecoveryAdvice(
        sleep: SleepData?,
        heart: HeartData?,
        recentActivity: [ActivityData]
    ) async throws -> AIInsight {
        let prompt = buildRecoveryPrompt(sleep: sleep, heart: heart, recentActivity: recentActivity)
        let response = try await model.generateContent(prompt)

        guard let text = response.text else {
            throw GeminiError.noResponse
        }

        return AIInsight(
            type: .recoveryAdvice,
            title: "Återhämtningsråd",
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
            title: "Veckorapport",
            content: text,
            metrics: ["sleep", "activity", "heart"],
            priority: .normal
        )
    }

    // MARK: - Chat

    func chat(message: String, context: HealthContext) async throws -> String {
        let prompt = """
        Du är en hälsorådgivare som hjälper användare förstå sin hälsodata.
        Svara på svenska, kort och koncist.

        Användarens senaste hälsodata:
        \(context.description)

        Användarens fråga: \(message)

        Ge ett hjälpsamt svar baserat på datan. Om du inte har tillräcklig data, säg det.
        """

        let response = try await model.generateContent(prompt)
        return response.text ?? "Kunde inte generera svar."
    }

    // MARK: - Private Helpers

    private func buildDailySummaryPrompt(sleep: SleepData?, activity: ActivityData?, heart: HeartData?) -> String {
        var dataDescription = "Analysera följande hälsodata och ge en kort daglig sammanfattning på svenska:\n\n"

        if let sleep = sleep {
            dataDescription += """
            SÖMN:
            - Total sömn: \(sleep.formattedDuration)
            - Djupsömn: \(Int(sleep.deepSleep / 60)) min
            - REM-sömn: \(Int(sleep.remSleep / 60)) min
            - Kvalitet: \(sleep.quality.displayText)

            """
        }

        if let activity = activity {
            dataDescription += """
            AKTIVITET:
            - Steg: \(activity.steps)
            - Aktiva kalorier: \(Int(activity.activeCalories)) kcal
            - Distans: \(activity.formattedDistance)
            - Träningsminuter: \(activity.exerciseMinutes) min

            """
        }

        if let heart = heart {
            dataDescription += """
            HJÄRTA:
            - Vilopuls: \(Int(heart.restingHeartRate)) bpm
            - HRV: \(heart.hrv.map { "\(Int($0)) ms" } ?? "Ej tillgänglig")

            """
        }

        dataDescription += """

        Ge en kort, uppmuntrande sammanfattning (2-3 meningar) av dagen.
        Inkludera ett konkret tips för förbättring om något kan förbättras.
        """

        return dataDescription
    }

    private func buildSleepAnalysisPrompt(sleepData: [SleepData]) -> String {
        var prompt = "Analysera följande sömndata från de senaste dagarna och ge insikter på svenska:\n\n"

        for (index, sleep) in sleepData.enumerated() {
            prompt += """
            Dag \(index + 1):
            - Total sömn: \(sleep.formattedDuration)
            - Djupsömn: \(Int(sleep.deepSleep / 60)) min (\(Int((sleep.deepSleep / sleep.totalDuration) * 100))%)
            - REM-sömn: \(Int(sleep.remSleep / 60)) min (\(Int((sleep.remSleep / sleep.totalDuration) * 100))%)
            - Kvalitet: \(sleep.quality.displayText)

            """
        }

        prompt += """

        Identifiera mönster och ge 2-3 konkreta tips för bättre sömn.
        Håll svaret kort och handlingsbart.
        """

        return prompt
    }

    private func buildRecoveryPrompt(sleep: SleepData?, heart: HeartData?, recentActivity: [ActivityData]) -> String {
        var prompt = "Baserat på följande data, bedöm återhämtningsstatus och ge råd på svenska:\n\n"

        if let sleep = sleep {
            prompt += "Sömn: \(sleep.formattedDuration), kvalitet: \(sleep.quality.displayText)\n"
        }

        if let heart = heart {
            prompt += "Vilopuls: \(Int(heart.restingHeartRate)) bpm\n"
            if let hrv = heart.hrv {
                prompt += "HRV: \(Int(hrv)) ms (\(heart.hrvStatus.displayText))\n"
            }
        }

        let totalActivity = recentActivity.reduce(0) { $0 + $1.exerciseMinutes }
        prompt += "Träning senaste dagarna: \(totalActivity) minuter totalt\n"

        prompt += """

        Ge en kort bedömning av återhämtningsstatus och rekommendation:
        - Är det en bra dag för intensiv träning?
        - Eller bör användaren fokusera på återhämtning?
        Håll svaret kort (2-3 meningar).
        """

        return prompt
    }

    private func buildWeeklyReportPrompt(sleepData: [SleepData], activityData: [ActivityData], heartData: [HeartData]) -> String {
        let avgSleep = sleepData.isEmpty ? 0 : sleepData.reduce(0) { $0 + $1.totalHours } / Double(sleepData.count)
        let avgSteps = activityData.isEmpty ? 0 : activityData.reduce(0) { $0 + $1.steps } / activityData.count
        let totalExercise = activityData.reduce(0) { $0 + $1.exerciseMinutes }
        let avgHR = heartData.isEmpty ? 0 : heartData.reduce(0) { $0 + $1.restingHeartRate } / Double(heartData.count)

        return """
        Skapa en veckorapport på svenska baserat på:

        SÖMN (veckosnitt):
        - Genomsnitt: \(String(format: "%.1f", avgSleep)) timmar/natt
        - Antal nätter med data: \(sleepData.count)

        AKTIVITET (veckan):
        - Genomsnitt steg: \(avgSteps)/dag
        - Total träning: \(totalExercise) minuter

        HJÄRTA:
        - Genomsnittlig vilopuls: \(Int(avgHR)) bpm

        Ge en sammanfattning med:
        1. Veckans höjdpunkter
        2. Ett område att förbättra
        3. Mål för nästa vecka
        Håll det kort och motiverande.
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
            desc += "Sömn: \(sleep.formattedDuration)\n"
        }
        if let activity = activity {
            desc += "Steg: \(activity.steps), Kalorier: \(Int(activity.activeCalories))\n"
        }
        if let heart = heart {
            desc += "Vilopuls: \(Int(heart.restingHeartRate)) bpm\n"
        }
        return desc.isEmpty ? "Ingen data tillgänglig" : desc
    }
}

enum GeminiError: LocalizedError {
    case noResponse
    case quotaExceeded
    case invalidRequest
    case invalidAPIKey

    var errorDescription: String? {
        switch self {
        case .noResponse: return "Kunde inte få svar från AI"
        case .quotaExceeded: return "AI-kvoten har överskridits"
        case .invalidRequest: return "Ogiltig förfrågan"
        case .invalidAPIKey: return "Ogiltig API-nyckel"
        }
    }
}
