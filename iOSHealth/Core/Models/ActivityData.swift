import Foundation

struct ActivityData: HealthMetric {
    let id: String
    let date: Date
    let type: MetricType = .activity

    let steps: Int
    let activeCalories: Double
    let totalCalories: Double
    let distance: Double // meters
    let exerciseMinutes: Int
    let standHours: Int
    let workouts: [WorkoutSummary]

    var distanceKm: Double {
        distance / 1000
    }

    var formattedDistance: String {
        String(format: "%.1f km", distanceKm)
    }

    var activityScore: Int {
        var score = 0

        // Steps (max 30 points for 10000+ steps)
        score += min(30, (steps * 30) / 10000)

        // Exercise minutes (max 30 points for 30+ minutes)
        score += min(30, exerciseMinutes)

        // Stand hours (max 20 points for 12 hours)
        score += min(20, (standHours * 20) / 12)

        // Active calories (max 20 points for 500+ calories)
        score += min(20, Int((activeCalories * 20) / 500))

        return min(100, score)
    }
}

struct WorkoutSummary: Codable, Identifiable {
    let id: String
    let workoutType: String
    let duration: TimeInterval
    let calories: Double
    let startTime: Date
    let averageHeartRate: Double?

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}
