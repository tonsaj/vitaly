import Foundation

struct HeartData: HealthMetric {
    let id: String
    let date: Date
    let type: MetricType = .heart

    let restingHeartRate: Double
    let averageHeartRate: Double
    let maxHeartRate: Double
    let minHeartRate: Double
    let hrv: Double? // Heart Rate Variability in ms
    let heartRateZones: [HeartRateZone]

    var hrvStatus: HRVStatus {
        guard let hrv = hrv else { return .unknown }

        if hrv >= 50 {
            return .excellent
        } else if hrv >= 35 {
            return .good
        } else if hrv >= 20 {
            return .fair
        } else {
            return .low
        }
    }

    var restingHRStatus: RestingHRStatus {
        if restingHeartRate < 60 {
            return .athletic
        } else if restingHeartRate < 70 {
            return .excellent
        } else if restingHeartRate < 80 {
            return .good
        } else if restingHeartRate < 90 {
            return .average
        } else {
            return .elevated
        }
    }
}

struct HeartRateZone: Codable, Identifiable {
    let id: String
    let zone: Int // 1-5
    let name: String
    let duration: TimeInterval
    let minBPM: Int
    let maxBPM: Int

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }

    static let zoneNames = [
        1: "Vila",
        2: "Lätt",
        3: "Aerob",
        4: "Anaerob",
        5: "Max"
    ]
}

enum HRVStatus: String {
    case excellent, good, fair, low, unknown

    var displayText: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Normal"
        case .low: return "Low"
        case .unknown: return "Unknown"
        }
    }
}

enum RestingHRStatus: String {
    case athletic, excellent, good, average, elevated

    var displayText: String {
        switch self {
        case .athletic: return "Athletic"
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .average: return "Normal"
        case .elevated: return "Elevated"
        }
    }
}
