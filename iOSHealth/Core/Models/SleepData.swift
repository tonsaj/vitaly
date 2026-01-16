import Foundation

struct SleepData: HealthMetric {
    let id: String
    let date: Date
    let type: MetricType = .sleep

    let totalDuration: TimeInterval // seconds
    let deepSleep: TimeInterval
    let remSleep: TimeInterval
    let lightSleep: TimeInterval
    let awake: TimeInterval
    let bedtime: Date?
    let wakeTime: Date?

    var quality: SleepQuality {
        let deepPercentage = deepSleep / totalDuration
        let remPercentage = remSleep / totalDuration

        if deepPercentage >= 0.2 && remPercentage >= 0.2 {
            return .excellent
        } else if deepPercentage >= 0.15 && remPercentage >= 0.15 {
            return .good
        } else if deepPercentage >= 0.1 || remPercentage >= 0.1 {
            return .fair
        } else {
            return .poor
        }
    }

    var totalHours: Double {
        totalDuration / 3600
    }

    var formattedDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

enum SleepQuality: String, Codable {
    case excellent
    case good
    case fair
    case poor

    var displayText: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }

    var score: Int {
        switch self {
        case .excellent: return 90
        case .good: return 75
        case .fair: return 55
        case .poor: return 30
        }
    }
}
