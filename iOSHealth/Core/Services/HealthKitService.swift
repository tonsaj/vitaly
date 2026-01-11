import Foundation
import HealthKit

final class HealthKitService {
    private let healthStore = HKHealthStore()

    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
        HKObjectType.quantityType(forIdentifier: .appleStandTime)!,
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.workoutType()
    ]

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isHealthKitAvailable else {
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

        guard !samples.isEmpty else { return nil }

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

        guard totalDuration > 0 else { return nil }

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

        return try await ActivityData(
            id: UUID().uuidString,
            date: date,
            steps: Int(steps),
            activeCalories: activeCalories,
            totalCalories: activeCalories + basalCalories,
            distance: distance,
            exerciseMinutes: Int(exerciseMinutes),
            standHours: Int(standTime / 3600),
            workouts: workouts
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

        return try await HeartData(
            id: UUID().uuidString,
            date: date,
            restingHeartRate: restingHR ?? stats.average,
            averageHeartRate: stats.average,
            maxHeartRate: stats.max,
            minHeartRate: stats.min,
            hrv: hrv,
            heartRateZones: []
        )
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
                if let error = error {
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
                if let error = error {
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
                if let error = error {
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
