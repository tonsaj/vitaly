import Foundation
import SwiftUI
import os.log

@Observable
final class BiologyViewModel {
    private let logger = Logger(subsystem: "com.perfectfools.vitaly", category: "Biology")

    // MARK: - Data
    var vo2Max: Double?
    var bodyFatPercentage: Double?
    var leanBodyMass: Double?
    var bodyMass: Double?

    var latestHRV: Double?
    var latestRHR: Double?

    var vo2MaxHistory: [DailyValue] = []
    var hrvHistory: [DailyValue] = []
    var rhrHistory: [DailyValue] = []
    var weightHistory: [DailyValue] = []

    var recentWorkouts: [WorkoutSummary] = []

    // MARK: - State
    var isLoading = false
    var isLoadingAI = false
    var aiSummary: String?
    var error: Error?
    var hasLoadedAI = false

    // MARK: - User Profile
    var heightCm: Double?
    var firestoreWeight: Double?
    var firestoreWaist: Double?

    // MARK: - Dependencies
    private let healthKitService: HealthKitService

    // MARK: - Computed Properties

    var vo2MaxStatus: VO2MaxStatus {
        guard let vo2 = vo2Max else { return .unknown }
        // Baserat på ålder 30-39 (kan förbättras med användarens faktiska ålder)
        switch vo2 {
        case 45...: return .excellent
        case 39..<45: return .good
        case 35..<39: return .fair
        case 31..<35: return .belowAverage
        default: return .poor
        }
    }

    var hrvTrend: TrendDirection {
        guard hrvHistory.count >= 7 else { return .stable }
        let recentAvg = hrvHistory.suffix(3).map(\.value).reduce(0, +) / 3
        let olderAvg = hrvHistory.prefix(4).map(\.value).reduce(0, +) / 4
        let diff = recentAvg - olderAvg
        if diff > 3 { return .increasing }
        if diff < -3 { return .decreasing }
        return .stable
    }

    var rhrTrend: TrendDirection {
        guard rhrHistory.count >= 7 else { return .stable }
        let recentAvg = rhrHistory.suffix(3).map(\.value).reduce(0, +) / 3
        let olderAvg = rhrHistory.prefix(4).map(\.value).reduce(0, +) / 4
        let diff = recentAvg - olderAvg
        // För RHR är lägre bättre
        if diff < -2 { return .increasing } // Improving
        if diff > 2 { return .decreasing } // Worsening
        return .stable
    }

    var rhrPercentile: Double {
        guard let rhr = latestRHR else { return 0 }
        // Ungefärlig percentil baserat på vilopuls
        // 50 bpm = ~95%, 60 bpm = ~75%, 70 bpm = ~50%, 80 bpm = ~25%
        let percentile = max(0, min(100, (80 - rhr) / 30 * 100))
        return percentile
    }

    var calculatedLeanBodyMass: Double? {
        guard let weight = bodyMass, let bodyFat = bodyFatPercentage else { return nil }
        return weight * (1 - bodyFat / 100)
    }

    var bodyFatStatus: (label: String, color: Color)? {
        guard let bodyFat = bodyFatPercentage else { return nil }
        // Based on men/women age group 30-39
        switch bodyFat {
        case ..<15:
            return ("Low", .blue)
        case 15..<20:
            return ("Healthy", .vitalyExcellent)
        case 20..<25:
            return ("Normal", .vitalyGood)
        case 25..<30:
            return ("Above Average", .yellow)
        default:
            return ("High", .red)
        }
    }

    // MARK: - Helper Methods

    private func calculateBMI() -> Double? {
        guard let weight = firestoreWeight ?? bodyMass, let height = heightCm, height > 0 else { return nil }
        let heightM = height / 100.0
        return weight / (heightM * heightM)
    }

    // MARK: - Init

    init(healthKitService: HealthKitService = HealthKitService(), heightCm: Double? = nil) {
        self.healthKitService = healthKitService
        self.heightCm = heightCm
    }

    // MARK: - Profile Update

    func updateHeight(_ height: Double?) {
        self.heightCm = height
    }

    // MARK: - Data Loading

    @MainActor
    func loadData() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Ladda alla data parallellt
            async let vo2 = healthKitService.fetchVO2Max()
            async let bodyFat = healthKitService.fetchBodyFatPercentage()
            async let leanMass = healthKitService.fetchLeanBodyMass()
            async let mass = healthKitService.fetchBodyMass()
            async let vo2History = healthKitService.fetchVO2MaxHistory(for: 30)
            async let hrvHist = healthKitService.fetchHRVHistory(for: 30)
            async let rhrHist = healthKitService.fetchRHRHistory(for: 30)
            async let workouts = healthKitService.fetchRecentWorkouts(limit: 5)
            async let weightHist = healthKitService.fetchWeightHistory(for: 90)

            self.vo2Max = try await vo2
            self.bodyFatPercentage = try await bodyFat
            self.leanBodyMass = try await leanMass
            self.bodyMass = try await mass
            self.vo2MaxHistory = try await vo2History
            self.hrvHistory = try await hrvHist
            self.rhrHistory = try await rhrHist
            self.recentWorkouts = try await workouts
            self.weightHistory = try await weightHist

            // Sätt senaste HRV och RHR från historiken
            self.latestHRV = hrvHistory.last(where: { $0.value > 0 })?.value
            self.latestRHR = rhrHistory.last(where: { $0.value > 0 })?.value

        } catch {
            logger.error("❌ Biology fel: \(error.localizedDescription)")
            self.error = error
        }

        isLoading = false

        // Ladda AI-sammanfattning efter att data har laddats
        await loadAISummary()
    }

    @MainActor
    private func loadAISummary() async {
        guard !hasLoadedAI else { return }
        hasLoadedAI = true
        isLoadingAI = true

        do {
            // Collect body data - prefer Firestore weight over HealthKit
            let currentWeight = firestoreWeight ?? bodyMass
            let weightText = currentWeight != nil ? "\(String(format: "%.1f", currentWeight!)) kg" : "not available"
            let bmiText = calculateBMI() != nil ? String(format: "%.1f", calculateBMI()!) : "not available"
            let bodyFatText = bodyFatPercentage != nil ? "\(String(format: "%.1f", bodyFatPercentage!))%" : "not available"
            let lbmText = leanBodyMass != nil ? "\(String(format: "%.1f", leanBodyMass!)) kg" : "not available"
            let vo2Text = vo2Max != nil ? "\(String(format: "%.1f", vo2Max!)) ml/kg/min" : "not available"
            let waistText = firestoreWaist != nil ? "\(String(format: "%.0f", firestoreWaist!)) cm" : "not available"

            // Only include metrics that have actual data
            var dataLines: [String] = []
            if currentWeight != nil { dataLines.append("- Weight: \(weightText)") }
            if firestoreWaist != nil { dataLines.append("- Waist circumference: \(waistText)") }
            if calculateBMI() != nil { dataLines.append("- BMI: \(bmiText)") }
            if bodyFatPercentage != nil { dataLines.append("- Body Fat: \(bodyFatText)") }
            if leanBodyMass != nil { dataLines.append("- Lean Body Mass: \(lbmText)") }
            if vo2Max != nil { dataLines.append("- VO2 Max: \(vo2Text)") }

            guard !dataLines.isEmpty else {
                aiSummary = "Add body measurements to get personalized insights."
                isLoadingAI = false
                return
            }

            let prompt = """
            Analyze this body data in English (max 2-3 sentences):
            \(dataLines.joined(separator: "\n"))

            Provide a brief health status summary focusing ONLY on the available data above. Do not mention missing data.

            IMPORTANT: Do NOT use any markdown formatting like **bold**, *italic*, bullet points, or emojis. Write plain text only.
            NEVER mention nutrition, diet, food, eating, meals, or any dietary advice.
            """

            aiSummary = try await GeminiService.shared.generateContent(prompt: prompt)
        } catch {
            logger.error("❌ AI summary error: \(error.localizedDescription)")
            aiSummary = "Add more body data to get personalized insights."
        }
        isLoadingAI = false
    }
}

// MARK: - Supporting Types

enum VO2MaxStatus: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case belowAverage = "Below Average"
    case poor = "Poor"
    case unknown = "Unknown"

    var color: Color {
        switch self {
        case .excellent: return .vitalyExcellent
        case .good: return .vitalyGood
        case .fair: return .vitalyFair
        case .belowAverage: return .vitalyFair
        case .poor: return .vitalyPoor
        case .unknown: return .vitalyTextSecondary
        }
    }
}

enum TrendDirection {
    case increasing
    case decreasing
    case stable

    var icon: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var text: String {
        switch self {
        case .increasing: return "Increasing"
        case .decreasing: return "Decreasing"
        case .stable: return "Stable"
        }
    }

    var color: Color {
        switch self {
        case .increasing: return .vitalyExcellent
        case .decreasing: return .vitalyFair
        case .stable: return .vitalyTextSecondary
        }
    }
}
