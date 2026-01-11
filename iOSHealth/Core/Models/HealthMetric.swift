import Foundation

enum MetricType: String, Codable, CaseIterable {
    case sleep
    case activity
    case heart
    case recovery

    var title: String {
        switch self {
        case .sleep: return "Sömn"
        case .activity: return "Aktivitet"
        case .heart: return "Hjärta"
        case .recovery: return "Återhämtning"
        }
    }

    var icon: String {
        switch self {
        case .sleep: return "moon.fill"
        case .activity: return "figure.run"
        case .heart: return "heart.fill"
        case .recovery: return "battery.100.bolt"
        }
    }

    var color: String {
        switch self {
        case .sleep: return "indigo"
        case .activity: return "green"
        case .heart: return "red"
        case .recovery: return "orange"
        }
    }
}

protocol HealthMetric: Codable, Identifiable {
    var id: String { get }
    var date: Date { get }
    var type: MetricType { get }
}
