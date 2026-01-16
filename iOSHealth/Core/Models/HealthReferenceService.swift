import Foundation
import SwiftUI

// MARK: - Health Reference Models

struct HealthReferenceData: Codable {
    let version: String
    let lastUpdated: String
    let metrics: [String: MetricReference]
}

struct MetricReference: Codable {
    let name: String
    let unit: String
    let description: String
    let higherIsBetter: Bool
    let ranges: [MetricRange]
}

struct MetricRange: Codable {
    let level: String
    let min: Double
    let max: Double
    let label: String
    let color: String
    let comment: String
}

// MARK: - Health Status

enum HealthStatus: String, CaseIterable {
    case veryPoor
    case poor
    case fair
    case good
    case excellent

    var displayName: String {
        switch self {
        case .veryPoor: return "Very Poor"
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }

    var color: Color {
        switch self {
        case .veryPoor: return Color(hex: "E53935")
        case .poor: return Color(hex: "FB8C00")
        case .fair: return Color(hex: "FDD835")
        case .good: return Color(hex: "7CB342")
        case .excellent: return Color(hex: "43A047")
        }
    }

    var icon: String {
        switch self {
        case .veryPoor: return "exclamationmark.triangle.fill"
        case .poor: return "arrow.down.circle.fill"
        case .fair: return "minus.circle.fill"
        case .good: return "arrow.up.circle.fill"
        case .excellent: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Metric Evaluation Result

struct MetricEvaluation {
    let status: HealthStatus
    let label: String
    let comment: String
    let color: Color
    let percentile: Double // 0-100, var i intervallet värdet ligger

    static let unknown = MetricEvaluation(
        status: .fair,
        label: "Unknown",
        comment: "No data available",
        color: .gray,
        percentile: 50
    )
}

// MARK: - Health Reference Service

final class HealthReferenceService {
    static let shared = HealthReferenceService()

    private var referenceData: HealthReferenceData?

    private init() {
        loadReferenceData()
    }

    private func loadReferenceData() {
        guard let url = Bundle.main.url(forResource: "HealthReferenceValues", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Could not load HealthReferenceValues.json")
            return
        }

        do {
            referenceData = try JSONDecoder().decode(HealthReferenceData.self, from: data)
        } catch {
            print("Error decoding HealthReferenceValues.json: \(error)")
        }
    }

    // MARK: - Evaluate Metrics

    func evaluate(metricKey: String, value: Double) -> MetricEvaluation {
        guard let metric = referenceData?.metrics[metricKey] else {
            return .unknown
        }

        // Hitta rätt intervall
        for range in metric.ranges {
            if value >= range.min && value < range.max {
                let status = HealthStatus(rawValue: range.level) ?? .fair
                let percentile = calculatePercentile(value: value, in: range)

                return MetricEvaluation(
                    status: status,
                    label: range.label,
                    comment: range.comment,
                    color: Color(hex: range.color),
                    percentile: percentile
                )
            }
        }

        // Om värdet är utanför alla intervall, returnera extremvärde
        if let firstRange = metric.ranges.first, value < firstRange.min {
            let status = HealthStatus(rawValue: firstRange.level) ?? .veryPoor
            return MetricEvaluation(
                status: status,
                label: firstRange.label,
                comment: firstRange.comment,
                color: Color(hex: firstRange.color),
                percentile: 0
            )
        }

        if let lastRange = metric.ranges.last, value >= lastRange.max {
            let status = HealthStatus(rawValue: lastRange.level) ?? .excellent
            return MetricEvaluation(
                status: status,
                label: lastRange.label,
                comment: lastRange.comment,
                color: Color(hex: lastRange.color),
                percentile: 100
            )
        }

        return .unknown
    }

    private func calculatePercentile(value: Double, in range: MetricRange) -> Double {
        let rangeSize = range.max - range.min
        guard rangeSize > 0 else { return 50 }
        return ((value - range.min) / rangeSize) * 100
    }

    // MARK: - Convenience Methods

    func evaluateSleep(hours: Double) -> MetricEvaluation {
        evaluate(metricKey: "sleep", value: hours)
    }

    func evaluateSteps(_ steps: Int) -> MetricEvaluation {
        evaluate(metricKey: "steps", value: Double(steps))
    }

    func evaluateRestingHeartRate(_ bpm: Double) -> MetricEvaluation {
        evaluate(metricKey: "restingHeartRate", value: bpm)
    }

    func evaluateHRV(_ ms: Double) -> MetricEvaluation {
        evaluate(metricKey: "hrv", value: ms)
    }

    func evaluateRespiratoryRate(_ rpm: Double) -> MetricEvaluation {
        evaluate(metricKey: "respiratoryRate", value: rpm)
    }

    func evaluateOxygenSaturation(_ percent: Double) -> MetricEvaluation {
        evaluate(metricKey: "oxygenSaturation", value: percent)
    }

    func evaluateVO2Max(_ value: Double) -> MetricEvaluation {
        evaluate(metricKey: "vo2Max", value: value)
    }

    func evaluateBodyFat(_ percent: Double) -> MetricEvaluation {
        evaluate(metricKey: "bodyFatPercentage", value: percent)
    }

    func evaluateActiveCalories(_ kcal: Double) -> MetricEvaluation {
        evaluate(metricKey: "activeCalories", value: kcal)
    }

    func evaluateExerciseMinutes(_ minutes: Int) -> MetricEvaluation {
        evaluate(metricKey: "exerciseMinutes", value: Double(minutes))
    }

    func evaluateDeepSleep(percentage: Double) -> MetricEvaluation {
        evaluate(metricKey: "deepSleepPercentage", value: percentage)
    }

    func evaluateREMSleep(percentage: Double) -> MetricEvaluation {
        evaluate(metricKey: "remSleepPercentage", value: percentage)
    }

    // MARK: - Get Reference Info

    func getMetricInfo(for key: String) -> MetricReference? {
        referenceData?.metrics[key]
    }
}
