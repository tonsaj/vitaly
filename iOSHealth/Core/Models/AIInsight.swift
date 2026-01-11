import Foundation
import FirebaseFirestore

struct AIInsight: Identifiable, Codable {
    @DocumentID var id: String?
    let type: InsightType
    let title: String
    let content: String
    let metrics: [String]
    let createdAt: Date
    var isRead: Bool
    let priority: InsightPriority

    init(id: String? = nil,
         type: InsightType,
         title: String,
         content: String,
         metrics: [String] = [],
         createdAt: Date = Date(),
         isRead: Bool = false,
         priority: InsightPriority = .normal) {
        self.id = id
        self.type = type
        self.title = title
        self.content = content
        self.metrics = metrics
        self.createdAt = createdAt
        self.isRead = isRead
        self.priority = priority
    }
}

enum InsightType: String, Codable {
    case dailySummary
    case sleepAnalysis
    case activityTrend
    case recoveryAdvice
    case heartHealth
    case weeklyReport

    var icon: String {
        switch self {
        case .dailySummary: return "sun.max.fill"
        case .sleepAnalysis: return "moon.fill"
        case .activityTrend: return "chart.line.uptrend.xyaxis"
        case .recoveryAdvice: return "battery.100.bolt"
        case .heartHealth: return "heart.fill"
        case .weeklyReport: return "calendar"
        }
    }

    var title: String {
        switch self {
        case .dailySummary: return "Daglig sammanfattning"
        case .sleepAnalysis: return "Sömnanalys"
        case .activityTrend: return "Aktivitetstrend"
        case .recoveryAdvice: return "Återhämtningsråd"
        case .heartHealth: return "Hjärthälsa"
        case .weeklyReport: return "Veckorapport"
        }
    }
}

enum InsightPriority: String, Codable {
    case low
    case normal
    case high

    var color: String {
        switch self {
        case .low: return "gray"
        case .normal: return "blue"
        case .high: return "orange"
        }
    }
}
