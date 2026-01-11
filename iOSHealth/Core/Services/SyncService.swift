import Foundation
import Combine

@MainActor
final class SyncService: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?

    private let healthKitService: HealthKitService
    private let firestoreService: FirestoreService
    private let geminiService: GeminiService

    private var userId: String?

    init(healthKitService: HealthKitService = HealthKitService(),
         firestoreService: FirestoreService = FirestoreService(),
         geminiService: GeminiService = GeminiService()) {
        self.healthKitService = healthKitService
        self.firestoreService = firestoreService
        self.geminiService = geminiService
    }

    func configure(userId: String) {
        self.userId = userId
    }

    func syncTodayData() async {
        guard let userId = userId else { return }

        isSyncing = true
        syncError = nil

        do {
            let today = Date()

            // Fetch from HealthKit
            async let sleepData = healthKitService.fetchSleepData(for: today)
            async let activityData = healthKitService.fetchActivityData(for: today)
            async let heartData = healthKitService.fetchHeartData(for: today)

            let (sleep, activity, heart) = try await (sleepData, activityData, heartData)

            // Save to Firestore
            try await firestoreService.saveHealthData(
                userId: userId,
                date: today,
                sleep: sleep,
                activity: activity,
                heart: heart
            )

            lastSyncDate = Date()
        } catch {
            syncError = error
        }

        isSyncing = false
    }

    func syncHistoricalData(days: Int = 7) async {
        guard let userId = userId else { return }

        isSyncing = true
        syncError = nil

        do {
            let calendar = Calendar.current

            for dayOffset in 0..<days {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }

                let sleep = try? await healthKitService.fetchSleepData(for: date)
                let activity = try? await healthKitService.fetchActivityData(for: date)
                let heart = try? await healthKitService.fetchHeartData(for: date)

                try await firestoreService.saveHealthData(
                    userId: userId,
                    date: date,
                    sleep: sleep,
                    activity: activity,
                    heart: heart
                )
            }

            lastSyncDate = Date()
        } catch {
            syncError = error
        }

        isSyncing = false
    }

    func generateDailyInsight() async throws -> AIInsight? {
        guard let userId = userId else { return nil }

        let today = Date()

        // Get today's data
        let sleep = try? await healthKitService.fetchSleepData(for: today)
        let activity = try? await healthKitService.fetchActivityData(for: today)
        let heart = try? await healthKitService.fetchHeartData(for: today)

        // Generate insight
        let insight = try await geminiService.generateDailySummary(
            sleep: sleep,
            activity: activity,
            heart: heart
        )

        // Save insight
        try await firestoreService.saveInsight(userId: userId, insight: insight)

        return insight
    }

    func generateWeeklyReport() async throws -> AIInsight? {
        guard let userId = userId else { return nil }

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else { return nil }

        // Fetch week's data
        let weekData = try await firestoreService.fetchHealthDataRange(
            userId: userId,
            from: startDate,
            to: endDate
        )

        let sleepData = weekData.compactMap { $0.1 }
        let activityData = weekData.compactMap { $0.2 }
        let heartData = weekData.compactMap { $0.3 }

        guard !sleepData.isEmpty || !activityData.isEmpty else {
            return nil
        }

        // Generate report
        let insight = try await geminiService.generateWeeklyReport(
            sleepData: sleepData,
            activityData: activityData,
            heartData: heartData
        )

        // Save insight
        try await firestoreService.saveInsight(userId: userId, insight: insight)

        return insight
    }
}
