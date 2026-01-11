import XCTest
@testable import iOSHealth

final class iOSHealthTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    // MARK: - Sleep Data Tests

    func testSleepQualityExcellent() throws {
        let sleep = SleepData(
            id: "test",
            date: Date(),
            totalDuration: 8 * 3600,
            deepSleep: 2 * 3600,  // 25%
            remSleep: 2 * 3600,   // 25%
            lightSleep: 4 * 3600,
            awake: 0,
            bedtime: nil,
            wakeTime: nil
        )

        XCTAssertEqual(sleep.quality, .excellent)
    }

    func testSleepQualityPoor() throws {
        let sleep = SleepData(
            id: "test",
            date: Date(),
            totalDuration: 8 * 3600,
            deepSleep: 0.5 * 3600,  // ~6%
            remSleep: 0.5 * 3600,   // ~6%
            lightSleep: 7 * 3600,
            awake: 0,
            bedtime: nil,
            wakeTime: nil
        )

        XCTAssertEqual(sleep.quality, .poor)
    }

    func testSleepFormattedDuration() throws {
        let sleep = SleepData(
            id: "test",
            date: Date(),
            totalDuration: 7.5 * 3600,
            deepSleep: 1.5 * 3600,
            remSleep: 1.5 * 3600,
            lightSleep: 4.5 * 3600,
            awake: 0,
            bedtime: nil,
            wakeTime: nil
        )

        XCTAssertEqual(sleep.formattedDuration, "7h 30m")
    }

    // MARK: - Activity Data Tests

    func testActivityScoreCalculation() throws {
        let activity = ActivityData(
            id: "test",
            date: Date(),
            steps: 10000,
            activeCalories: 500,
            totalCalories: 2500,
            distance: 8000,
            exerciseMinutes: 30,
            standHours: 12,
            workouts: []
        )

        // Max score should be 100
        XCTAssertEqual(activity.activityScore, 100)
    }

    func testActivityScoreLow() throws {
        let activity = ActivityData(
            id: "test",
            date: Date(),
            steps: 2000,
            activeCalories: 100,
            totalCalories: 1800,
            distance: 1500,
            exerciseMinutes: 5,
            standHours: 4,
            workouts: []
        )

        XCTAssertLessThan(activity.activityScore, 50)
    }

    // MARK: - Heart Data Tests

    func testHRVStatusExcellent() throws {
        let heart = HeartData(
            id: "test",
            date: Date(),
            restingHeartRate: 55,
            averageHeartRate: 70,
            maxHeartRate: 150,
            minHeartRate: 50,
            hrv: 60,
            heartRateZones: []
        )

        XCTAssertEqual(heart.hrvStatus, .excellent)
    }

    func testHRVStatusLow() throws {
        let heart = HeartData(
            id: "test",
            date: Date(),
            restingHeartRate: 75,
            averageHeartRate: 85,
            maxHeartRate: 160,
            minHeartRate: 60,
            hrv: 15,
            heartRateZones: []
        )

        XCTAssertEqual(heart.hrvStatus, .low)
    }

    func testRestingHRStatusAthletic() throws {
        let heart = HeartData(
            id: "test",
            date: Date(),
            restingHeartRate: 55,
            averageHeartRate: 70,
            maxHeartRate: 150,
            minHeartRate: 50,
            hrv: 50,
            heartRateZones: []
        )

        XCTAssertEqual(heart.restingHRStatus, .athletic)
    }

    // MARK: - User Settings Tests

    func testUserSettingsDefault() throws {
        let settings = UserSettings()

        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertTrue(settings.dailyInsightsEnabled)
        XCTAssertEqual(settings.preferredUnits, .metric)
    }
}
