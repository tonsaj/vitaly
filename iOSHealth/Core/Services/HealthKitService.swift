import Foundation
import HealthKit
import os.log

final class HealthKitService {
    private let healthStore = HKHealthStore()
    private let logger = Logger(subsystem: "com.perfectfools.vitaly", category: "HealthKit")

    private let readTypes: Set<HKObjectType> = [
        // Hjärta
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        // Aktivitet
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
        HKObjectType.quantityType(forIdentifier: .appleStandTime)!,
        // Sömn
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        // Träning
        HKObjectType.workoutType(),
        // Biologi / Kroppssammansättning
        HKObjectType.quantityType(forIdentifier: .vo2Max)!,
        HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
        HKObjectType.quantityType(forIdentifier: .leanBodyMass)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!
    ]

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Cached Latest Data (for AI insights)
    var latestSleepData: SleepData?
    var latestActivityData: ActivityData?
    var latestHeartData: HeartData?

    func requestAuthorization() async throws {
        guard isHealthKitAvailable else {
            logger.error("❌ HealthKit är inte tillgängligt på denna enhet")
            throw HealthKitError.notAvailable
        }
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    func checkAuthorizationStatus() -> HKAuthorizationStatus {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return .notDetermined
        }
        return healthStore.authorizationStatus(for: heartRateType)
    }

    // MARK: - Sleep Data

    func fetchSleepData(for date: Date) async throws -> SleepData? {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        // Include previous night's sleep
        let sleepStart = Calendar.current.date(byAdding: .hour, value: -12, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: sleepStart, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples as? [HKCategorySample] ?? [])
                }
            }
            healthStore.execute(query)
        }

        guard !samples.isEmpty else {
            return nil
        }

        var deepSleep: TimeInterval = 0
        var remSleep: TimeInterval = 0
        var lightSleep: TimeInterval = 0
        var awake: TimeInterval = 0
        var bedtime: Date?
        var wakeTime: Date?

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)

            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                deepSleep += duration
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                remSleep += duration
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                lightSleep += duration
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                awake += duration
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                if bedtime == nil { bedtime = sample.startDate }
                wakeTime = sample.endDate
            default:
                break
            }
        }

        let totalDuration = deepSleep + remSleep + lightSleep

        guard totalDuration > 0 else {
            return nil
        }

        return SleepData(
            id: UUID().uuidString,
            date: date,
            totalDuration: totalDuration,
            deepSleep: deepSleep,
            remSleep: remSleep,
            lightSleep: lightSleep,
            awake: awake,
            bedtime: bedtime,
            wakeTime: wakeTime
        )
    }

    // MARK: - Activity Data

    func fetchActivityData(for date: Date) async throws -> ActivityData {

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        async let steps = fetchSum(for: .stepCount, start: startOfDay, end: endOfDay)
        async let activeCalories = fetchSum(for: .activeEnergyBurned, start: startOfDay, end: endOfDay)
        async let basalCalories = fetchSum(for: .basalEnergyBurned, start: startOfDay, end: endOfDay)
        async let distance = fetchSum(for: .distanceWalkingRunning, start: startOfDay, end: endOfDay)
        async let exerciseMinutes = fetchSum(for: .appleExerciseTime, start: startOfDay, end: endOfDay)
        async let standTime = fetchSum(for: .appleStandTime, start: startOfDay, end: endOfDay)
        async let workouts = fetchWorkouts(start: startOfDay, end: endOfDay)

        let stepsValue = try await steps
        let activeCal = try await activeCalories
        let basalCal = try await basalCalories
        let dist = try await distance
        let exercise = try await exerciseMinutes
        let stand = try await standTime
        let workoutList = try await workouts

        return ActivityData(
            id: UUID().uuidString,
            date: date,
            steps: Int(stepsValue),
            activeCalories: activeCal,
            totalCalories: activeCal + basalCal,
            distance: dist,
            exerciseMinutes: Int(exercise),
            standHours: Int(stand / 3600),
            workouts: workoutList
        )
    }

    // MARK: - Heart Data

    func fetchHeartData(for date: Date) async throws -> HeartData {

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        async let restingHR = fetchMostRecent(for: .restingHeartRate, start: startOfDay, end: endOfDay)
        async let hrv = fetchMostRecent(for: .heartRateVariabilitySDNN, start: startOfDay, end: endOfDay)
        async let heartRateStats = fetchHeartRateStats(start: startOfDay, end: endOfDay)

        let stats = try await heartRateStats
        let rhr = try await restingHR
        let hrvValue = try await hrv

        return HeartData(
            id: UUID().uuidString,
            date: date,
            restingHeartRate: rhr ?? stats.average,
            averageHeartRate: stats.average,
            maxHeartRate: stats.max,
            minHeartRate: stats.min,
            hrv: hrvValue,
            heartRateZones: []
        )
    }

    // MARK: - Historical Data

    func fetchWeeklyData() async throws -> WeeklyHealthData {
        let calendar = Calendar.current
        let today = Date()

        var sleepData: [SleepData?] = []
        var activityData: [ActivityData] = []
        var heartData: [HeartData] = []

        // Hämta data för de senaste 7 dagarna
        for dayOffset in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!

            async let sleep = fetchSleepData(for: date)
            async let activity = fetchActivityData(for: date)
            async let heart = fetchHeartData(for: date)

            sleepData.append(try await sleep)
            activityData.append(try await activity)
            heartData.append(try await heart)
        }

        return WeeklyHealthData(
            sleepData: sleepData,
            activityData: activityData,
            heartData: heartData
        )
    }

    func fetchYesterdayData() async throws -> DailyHealthData {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        async let sleep = fetchSleepData(for: yesterday)
        async let activity = fetchActivityData(for: yesterday)
        async let heart = fetchHeartData(for: yesterday)

        return try await DailyHealthData(
            date: yesterday,
            sleep: sleep,
            activity: activity,
            heart: heart
        )
    }

    func fetchDailySteps(for days: Int) async throws -> [DailyValue] {
        let calendar = Calendar.current
        let today = Date()
        var results: [DailyValue] = []

        for dayOffset in (0..<days).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let steps = try await fetchSum(for: .stepCount, start: startOfDay, end: endOfDay)
            results.append(DailyValue(date: date, value: steps))
        }

        return results
    }

    func fetchDailySleep(for days: Int) async throws -> [DailyValue] {
        let calendar = Calendar.current
        let today = Date()
        var results: [DailyValue] = []

        for dayOffset in (0..<days).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let sleepData = try await fetchSleepData(for: date)
            let hours = (sleepData?.totalDuration ?? 0) / 3600
            results.append(DailyValue(date: date, value: hours))
        }

        return results
    }

    func fetchDailyHRV(for days: Int) async throws -> [DailyValue] {
        let calendar = Calendar.current
        let today = Date()
        var results: [DailyValue] = []

        for dayOffset in (0..<days).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let hrv = try await fetchMostRecent(for: .heartRateVariabilitySDNN, start: startOfDay, end: endOfDay)
            results.append(DailyValue(date: date, value: hrv ?? 0))
        }

        return results
    }

    func fetchDailyRestingHR(for days: Int) async throws -> [DailyValue] {
        let calendar = Calendar.current
        let today = Date()
        var results: [DailyValue] = []

        for dayOffset in (0..<days).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let rhr = try await fetchMostRecent(for: .restingHeartRate, start: startOfDay, end: endOfDay)
            results.append(DailyValue(date: date, value: rhr ?? 0))
        }

        return results
    }

    // MARK: - Biology Data

    func fetchVO2Max() async throws -> Double? {
        return try await fetchMostRecentAllTime(for: .vo2Max)
    }

    func fetchBodyFatPercentage() async throws -> Double? {
        let value = try await fetchMostRecentAllTime(for: .bodyFatPercentage)
        if let v = value {
            return v * 100 // HealthKit lagrar som decimal (0.15 = 15%)
        }
        return nil
    }

    func fetchLeanBodyMass() async throws -> Double? {
        return try await fetchMostRecentAllTime(for: .leanBodyMass)
    }

    func fetchBodyMass() async throws -> Double? {
        return try await fetchMostRecentAllTime(for: .bodyMass)
    }

    func fetchVO2MaxHistory(for days: Int) async throws -> [DailyValue] {
        return try await fetchHistoricalData(for: .vo2Max, days: days)
    }

    func fetchHRVHistory(for days: Int) async throws -> [DailyValue] {
        return try await fetchDailyHRV(for: days)
    }

    func fetchRHRHistory(for days: Int) async throws -> [DailyValue] {
        return try await fetchDailyRestingHR(for: days)
    }

    // MARK: - Weight & Energy History

    func fetchWeightHistory(for days: Int) async throws -> [DailyValue] {
        return try await fetchHistoricalData(for: .bodyMass, days: days)
    }

    func fetchDailyTotalEnergy(for days: Int) async throws -> [DailyValue] {
        let calendar = Calendar.current
        let today = Date()
        var results: [DailyValue] = []

        for dayOffset in (0..<days).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let activeEnergy = try await fetchSum(for: .activeEnergyBurned, start: startOfDay, end: endOfDay)
            let basalEnergy = try await fetchSum(for: .basalEnergyBurned, start: startOfDay, end: endOfDay)
            results.append(DailyValue(date: date, value: activeEnergy + basalEnergy))
        }

        return results
    }

    func fetchRecentWorkouts(limit: Int = 10) async throws -> [WorkoutSummary] {

        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!

        let predicate = HKQuery.predicateForSamples(withStart: thirtyDaysAgo, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = (samples as? [HKWorkout])?.map { workout in
                    WorkoutSummary(
                        id: workout.uuid.uuidString,
                        workoutType: workout.workoutActivityType.name,
                        duration: workout.duration,
                        calories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                        startTime: workout.startDate,
                        averageHeartRate: nil
                    )
                } ?? []

                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }

    /// Hämtar senaste värde oavsett datum
    private func fetchMostRecentAllTime(for identifier: HKQuantityTypeIdentifier) async throws -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                // Ignorera "no data" fel
                if let error = error {
                    if error.localizedDescription.contains("No data") {
                        continuation.resume(returning: nil)
                        return
                    }
                    continuation.resume(throwing: error)
                    return
                }

                let unit = self.unit(for: identifier)
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    /// Hämtar historisk data för en metrik
    private func fetchHistoricalData(for identifier: HKQuantityTypeIdentifier, days: Int) async throws -> [DailyValue] {
        let calendar = Calendar.current
        let today = Date()
        var results: [DailyValue] = []

        for dayOffset in (0..<days).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let value = try await fetchMostRecent(for: identifier, start: startOfDay, end: endOfDay)
            results.append(DailyValue(date: date, value: value ?? 0))
        }

        return results
    }

    // MARK: - Private Helpers

    private func fetchSum(for identifier: HKQuantityTypeIdentifier, start: Date, end: Date) async throws -> Double {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return 0
        }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                // Ignorera "no data" fel
                if let error = error {
                    if error.localizedDescription.contains("No data") {
                        continuation.resume(returning: 0)
                        return
                    }
                    continuation.resume(throwing: error)
                    return
                }

                let unit = self.unit(for: identifier)
                let value = statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func fetchMostRecent(for identifier: HKQuantityTypeIdentifier, start: Date, end: Date) async throws -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                // Ignorera "no data" fel
                if let error = error {
                    if error.localizedDescription.contains("No data") {
                        continuation.resume(returning: nil)
                        return
                    }
                    continuation.resume(throwing: error)
                    return
                }

                let unit = self.unit(for: identifier)
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func fetchHeartRateStats(start: Date, end: Date) async throws -> (average: Double, min: Double, max: Double) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return (0, 0, 0)
        }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: [.discreteAverage, .discreteMin, .discreteMax]
            ) { _, statistics, error in
                // Ignorera "no data" fel - returnera bara tomma värden
                if let error = error {
                    let nsError = error as NSError
                    // HKErrorNoData = 11, eller "No data available"
                    if nsError.domain == "com.apple.healthkit" || nsError.localizedDescription.contains("No data") {
                        continuation.resume(returning: (0, 0, 0))
                        return
                    }
                    continuation.resume(throwing: error)
                    return
                }

                let unit = HKUnit.count().unitDivided(by: .minute())
                let avg = statistics?.averageQuantity()?.doubleValue(for: unit) ?? 0
                let min = statistics?.minimumQuantity()?.doubleValue(for: unit) ?? 0
                let max = statistics?.maximumQuantity()?.doubleValue(for: unit) ?? 0

                continuation.resume(returning: (avg, min, max))
            }
            healthStore.execute(query)
        }
    }

    private func fetchWorkouts(start: Date, end: Date) async throws -> [WorkoutSummary] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = (samples as? [HKWorkout])?.map { workout in
                    WorkoutSummary(
                        id: workout.uuid.uuidString,
                        workoutType: workout.workoutActivityType.name,
                        duration: workout.duration,
                        calories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                        startTime: workout.startDate,
                        averageHeartRate: nil
                    )
                } ?? []

                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }

    private func unit(for identifier: HKQuantityTypeIdentifier) -> HKUnit {
        switch identifier {
        case .stepCount:
            return .count()
        case .activeEnergyBurned, .basalEnergyBurned:
            return .kilocalorie()
        case .distanceWalkingRunning:
            return .meter()
        case .appleExerciseTime, .appleStandTime:
            return .minute()
        case .heartRate, .restingHeartRate:
            return HKUnit.count().unitDivided(by: .minute())
        case .heartRateVariabilitySDNN:
            return .secondUnit(with: .milli)
        // Biologi / Kroppssammansättning
        case .vo2Max:
            return HKUnit.literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo).unitMultiplied(by: .minute()))
        case .bodyFatPercentage:
            return .percent()
        case .leanBodyMass, .bodyMass:
            return .gramUnit(with: .kilo)
        default:
            return .count()
        }
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case dataNotAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable: return "HealthKit är inte tillgängligt på den här enheten"
        case .notAuthorized: return "Appen har inte behörighet att läsa hälsodata"
        case .dataNotAvailable: return "Ingen hälsodata tillgänglig"
        }
    }
}

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Löpning"
        case .walking: return "Promenad"
        case .cycling: return "Cykling"
        case .swimming: return "Simning"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Styrketräning"
        case .highIntensityIntervalTraining: return "HIIT"
        case .hiking: return "Vandring"
        default: return "Träning"
        }
    }
}

// MARK: - Data Models for Historical Data

struct WeeklyHealthData {
    let sleepData: [SleepData?]
    let activityData: [ActivityData]
    let heartData: [HeartData]

    var averageSleepHours: Double {
        // Filtrera bort nil OCH 0-värden (ingen mätning)
        let validSleep = sleepData.compactMap { $0 }.filter { $0.totalHours > 0 }
        guard !validSleep.isEmpty else { return 0 }
        return validSleep.map { $0.totalHours }.reduce(0, +) / Double(validSleep.count)
    }

    var averageSteps: Int {
        // Filtrera bort 0-värden (ingen mätning)
        let validSteps = activityData.filter { $0.steps > 0 }
        guard !validSteps.isEmpty else { return 0 }
        return validSteps.map { $0.steps }.reduce(0, +) / validSteps.count
    }

    var averageHRV: Double {
        // Filtrera bort nil OCH 0-värden
        let validHRV = heartData.compactMap { $0.hrv }.filter { $0 > 0 }
        guard !validHRV.isEmpty else { return 0 }
        return validHRV.reduce(0, +) / Double(validHRV.count)
    }

    var averageRHR: Double {
        // Filtrera bort 0-värden
        let validRHR = heartData.map { $0.restingHeartRate }.filter { $0 > 0 }
        guard !validRHR.isEmpty else { return 0 }
        return validRHR.reduce(0, +) / Double(validRHR.count)
    }
}

struct DailyHealthData {
    let date: Date
    let sleep: SleepData?
    let activity: ActivityData
    let heart: HeartData
}

struct DailyValue: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double

    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter.string(from: date)
    }
}
