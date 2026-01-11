import Foundation
import SwiftUI

@Observable
final class DashboardViewModel {
    // MARK: - Published State
    var sleepData: SleepData?
    var activityData: ActivityData?
    var heartData: HeartData?

    var isLoading = false
    var error: Error?
    var lastRefreshDate: Date?
    var isDemoMode = false

    // MARK: - Dependencies
    private let healthKitService: HealthKitService

    // MARK: - Computed Properties
    var hasData: Bool {
        sleepData != nil || activityData != nil || heartData != nil
    }

    var todayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter.string(from: Date())
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
            // Convert HRV status to score
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
        case 85...100: return "Utmärkt"
        case 70..<85: return "Mycket bra"
        case 55..<70: return "Bra"
        case 40..<55: return "Okej"
        default: return "Behöver förbättras"
        }
    }

    // MARK: - Weekly Trend Data
    var weeklyTrendData: [DayTrendData] {
        // Demo data för 7 dagar
        let days = ["Mån", "Tis", "Ons", "Tor", "Fre", "Lör", "Sön"]
        let scores = [72.0, 68.0, 78.0, 82.0, 75.0, 85.0, Double(overallScore)]
        return zip(days, scores).map { DayTrendData(dayName: $0, score: $1) }
    }

    var averageSleepHours: Double {
        // Demo-värde, ska beräknas från historisk data
        guard let sleep = sleepData else { return 7.2 }
        return sleep.totalHours
    }

    var averageSteps: Int {
        // Demo-värde
        guard let activity = activityData else { return 8500 }
        return activity.steps
    }

    var averageHRV: Double {
        // Demo-värde
        guard let heart = heartData, let hrv = heart.hrv else { return 52 }
        return hrv
    }

    // MARK: - Init
    init(healthKitService: HealthKitService = HealthKitService()) {
        self.healthKitService = healthKitService
    }

    // MARK: - Data Loading
    @MainActor
    func loadTodayData() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Request HealthKit authorization if not determined
            let authStatus = healthKitService.checkAuthorizationStatus()
            if authStatus == .notDetermined {
                try await healthKitService.requestAuthorization()
            }

            let today = Date()

            // Fetch all data in parallel
            async let sleep = healthKitService.fetchSleepData(for: today)
            async let activity = healthKitService.fetchActivityData(for: today)
            async let heart = healthKitService.fetchHeartData(for: today)

            self.sleepData = try await sleep
            self.activityData = try await activity
            self.heartData = try await heart

            lastRefreshDate = Date()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    @MainActor
    func refresh() async {
        await loadTodayData()
    }

    // MARK: - Demo Mode
    @MainActor
    func loadDemoData() {
        isDemoMode = true
        error = nil

        let now = Date()
        let calendar = Calendar.current

        // Demo sleep data - 7h 32m of sleep
        sleepData = SleepData(
            id: UUID().uuidString,
            date: now,
            totalDuration: 27120, // 7h 32m
            deepSleep: 5400,      // 1h 30m
            remSleep: 7200,       // 2h
            lightSleep: 14520,    // 4h 2m
            awake: 1800,          // 30m
            bedtime: calendar.date(byAdding: .hour, value: -8, to: calendar.startOfDay(for: now)),
            wakeTime: calendar.date(byAdding: .minute, value: 32, to: calendar.startOfDay(for: now))
        )

        // Demo activity data
        activityData = ActivityData(
            id: UUID().uuidString,
            date: now,
            steps: 8547,
            activeCalories: 423,
            totalCalories: 2180,
            distance: 6234,
            exerciseMinutes: 42,
            standHours: 10,
            workouts: [
                WorkoutSummary(
                    id: UUID().uuidString,
                    workoutType: "Löpning",
                    duration: 1860, // 31 min
                    calories: 312,
                    startTime: calendar.date(byAdding: .hour, value: -3, to: now)!,
                    averageHeartRate: 145
                )
            ]
        )

        // Demo heart data
        heartData = HeartData(
            id: UUID().uuidString,
            date: now,
            restingHeartRate: 58,
            averageHeartRate: 72,
            maxHeartRate: 156,
            minHeartRate: 52,
            hrv: 48,
            heartRateZones: []
        )

        lastRefreshDate = now
    }
}
