import Foundation
import SwiftUI

@MainActor
@Observable
class HealthViewModel {
    // MARK: - Published State
    var selectedDate: Date = Date()
    var sleepData: SleepData?
    var activityData: ActivityData?
    var heartData: HeartData?
    var historicalSleep: [SleepData] = []
    var historicalActivity: [ActivityData] = []
    var historicalHeart: [HeartData] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Recovery Calculation
    var recoveryScore: Int {
        guard let sleep = sleepData, let heart = heartData else {
            return 0
        }

        // Recovery is based on sleep quality (60%) and HRV (40%)
        let sleepScore = sleep.quality.score
        let hrvScore: Int

        if let hrv = heart.hrv {
            hrvScore = heart.hrvStatus == .excellent ? 90 :
                       heart.hrvStatus == .good ? 75 :
                       heart.hrvStatus == .fair ? 55 : 30
        } else {
            hrvScore = 50 // neutral if no HRV data
        }

        return Int((Double(sleepScore) * 0.6) + (Double(hrvScore) * 0.4))
    }

    var recoveryStatus: RecoveryStatus {
        let score = recoveryScore

        if score >= 80 {
            return .optimal
        } else if score >= 65 {
            return .good
        } else if score >= 50 {
            return .fair
        } else {
            return .needsRest
        }
    }

    var recoveryRecommendation: String {
        switch recoveryStatus {
        case .optimal:
            return "Du är väl återhämtad och redo för hög intensitet. Perfekt dag för tuffa pass."
        case .good:
            return "Bra återhämtning. Du kan träna normalt men lyssna på din kropp."
        case .fair:
            return "Måttlig återhämtning. Överväg lättare träning eller aktiv vila idag."
        case .needsRest:
            return "Din kropp behöver vila. Prioritera sömn och återhämtning idag."
        }
    }

    // MARK: - Contributing Factors
    var recoveryFactors: [(String, String, RecoveryFactorStatus)] {
        var factors: [(String, String, RecoveryFactorStatus)] = []

        // Sleep factor
        if let sleep = sleepData {
            let status: RecoveryFactorStatus
            if sleep.quality == .excellent || sleep.quality == .good {
                status = .positive
            } else if sleep.quality == .fair {
                status = .neutral
            } else {
                status = .negative
            }
            factors.append(("Sömn", sleep.formattedDuration, status))
        }

        // HRV factor
        if let heart = heartData, let hrv = heart.hrv {
            let status: RecoveryFactorStatus
            switch heart.hrvStatus {
            case .excellent, .good:
                status = .positive
            case .fair:
                status = .neutral
            case .low, .unknown:
                status = .negative
            }
            factors.append(("HRV", String(format: "%.0f ms", hrv), status))
        }

        // Resting heart rate factor
        if let heart = heartData {
            let status: RecoveryFactorStatus
            switch heart.restingHRStatus {
            case .athletic, .excellent:
                status = .positive
            case .good:
                status = .neutral
            default:
                status = .negative
            }
            factors.append(("Vilopuls", String(format: "%.0f bpm", heart.restingHeartRate), status))
        }

        // Activity strain (from previous day if available)
        if let activity = activityData {
            let strain = activity.activityScore
            let status: RecoveryFactorStatus = strain > 80 ? .negative : strain > 50 ? .neutral : .positive
            factors.append(("Belastning", "\(strain)%", status))
        }

        return factors
    }

    // MARK: - Date Navigation
    func navigateToToday() {
        selectedDate = Date()
        Task {
            await fetchData()
        }
    }

    func navigateToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        Task {
            await fetchData()
        }
    }

    func navigateToNextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        Task {
            await fetchData()
        }
    }

    // MARK: - Data Fetching
    func fetchData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Simulate API call - replace with actual service calls
            try await Task.sleep(for: .milliseconds(500))

            // Fetch current day data
            sleepData = generateMockSleepData(for: selectedDate)
            activityData = generateMockActivityData(for: selectedDate)
            heartData = generateMockHeartData(for: selectedDate)

            // Fetch historical data (last 7 days)
            await fetchHistoricalData()

        } catch {
            errorMessage = "Kunde inte hämta data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func fetchHistoricalData() async {
        historicalSleep = []
        historicalActivity = []
        historicalHeart = []

        let calendar = Calendar.current

        for dayOffset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: selectedDate) {
                historicalSleep.append(generateMockSleepData(for: date))
                historicalActivity.append(generateMockActivityData(for: date))
                historicalHeart.append(generateMockHeartData(for: date))
            }
        }
    }

    // MARK: - Mock Data Generators (Replace with actual service calls)
    private func generateMockSleepData(for date: Date) -> SleepData {
        let baseHours = Double.random(in: 6.5...8.5)
        let totalDuration = baseHours * 3600

        return SleepData(
            id: UUID().uuidString,
            date: date,
            totalDuration: totalDuration,
            deepSleep: totalDuration * Double.random(in: 0.15...0.25),
            remSleep: totalDuration * Double.random(in: 0.18...0.28),
            lightSleep: totalDuration * Double.random(in: 0.40...0.50),
            awake: totalDuration * Double.random(in: 0.02...0.08),
            bedtime: Calendar.current.date(bySettingHour: 23, minute: Int.random(in: 0...59), second: 0, of: date),
            wakeTime: Calendar.current.date(bySettingHour: 7, minute: Int.random(in: 0...59), second: 0, of: date)
        )
    }

    private func generateMockActivityData(for date: Date) -> ActivityData {
        let steps = Int.random(in: 5000...15000)
        let activeCalories = Double.random(in: 300...700)

        return ActivityData(
            id: UUID().uuidString,
            date: date,
            steps: steps,
            activeCalories: activeCalories,
            totalCalories: activeCalories + 1800,
            distance: Double(steps) * 0.75,
            exerciseMinutes: Int.random(in: 15...60),
            standHours: Int.random(in: 8...14),
            workouts: generateMockWorkouts(for: date)
        )
    }

    private func generateMockHeartData(for date: Date) -> HeartData {
        let restingHR = Double.random(in: 55...75)

        return HeartData(
            id: UUID().uuidString,
            date: date,
            restingHeartRate: restingHR,
            averageHeartRate: restingHR + Double.random(in: 15...30),
            maxHeartRate: Double.random(in: 150...180),
            minHeartRate: restingHR - Double.random(in: 5...10),
            hrv: Double.random(in: 30...70),
            heartRateZones: [
                HeartRateZone(id: "1", zone: 1, name: "Vila", duration: 3600 * 20, minBPM: 50, maxBPM: 90),
                HeartRateZone(id: "2", zone: 2, name: "Lätt", duration: 3600 * 2, minBPM: 90, maxBPM: 120),
                HeartRateZone(id: "3", zone: 3, name: "Aerob", duration: 1800, minBPM: 120, maxBPM: 140),
                HeartRateZone(id: "4", zone: 4, name: "Anaerob", duration: 900, minBPM: 140, maxBPM: 160),
                HeartRateZone(id: "5", zone: 5, name: "Max", duration: 300, minBPM: 160, maxBPM: 180)
            ]
        )
    }

    private func generateMockWorkouts(for date: Date) -> [WorkoutSummary] {
        let workoutTypes = ["Löpning", "Cykling", "Styrketräning", "Yoga", "Promenad"]
        let count = Int.random(in: 0...2)

        return (0..<count).map { index in
            WorkoutSummary(
                id: UUID().uuidString,
                workoutType: workoutTypes.randomElement()!,
                duration: TimeInterval(Int.random(in: 20...60) * 60),
                calories: Double.random(in: 150...500),
                startTime: Calendar.current.date(byAdding: .hour, value: -index * 3, to: date) ?? date,
                averageHeartRate: Double.random(in: 120...160)
            )
        }
    }
}

// MARK: - Supporting Types
enum RecoveryStatus {
    case optimal, good, fair, needsRest

    var displayText: String {
        switch self {
        case .optimal: return "Optimal"
        case .good: return "Bra"
        case .fair: return "Måttlig"
        case .needsRest: return "Behöver vila"
        }
    }

    var color: Color {
        switch self {
        case .optimal: return .vitalyRecovery
        case .good: return .vitalyGood
        case .fair: return .vitalyFair
        case .needsRest: return .vitalyPoor
        }
    }

    var icon: String {
        switch self {
        case .optimal: return "checkmark.circle.fill"
        case .good: return "hand.thumbsup.fill"
        case .fair: return "exclamationmark.triangle.fill"
        case .needsRest: return "bed.double.fill"
        }
    }
}

enum RecoveryFactorStatus {
    case positive, neutral, negative

    var color: Color {
        switch self {
        case .positive: return .vitalyExcellent
        case .neutral: return .vitalyFair
        case .negative: return .vitalyPoor
        }
    }
}

