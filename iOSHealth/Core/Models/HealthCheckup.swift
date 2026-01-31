import Foundation
import FirebaseFirestore
import SwiftUI

// MARK: - Lab Category

enum LabCategory: String, Codable, CaseIterable {
    case cholesterol = "cholesterol"
    case bloodSugar = "blood_sugar"
    case liver = "liver"
    case kidney = "kidney"
    case thyroid = "thyroid"
    case bloodCount = "blood_count"
    case inflammation = "inflammation"
    case vitamins = "vitamins"
    case hormones = "hormones"
    case other = "other"

    var displayName: String {
        switch self {
        case .cholesterol: return "Cholesterol"
        case .bloodSugar: return "Blood Sugar"
        case .liver: return "Liver"
        case .kidney: return "Kidney"
        case .thyroid: return "Thyroid"
        case .bloodCount: return "Blood Count"
        case .inflammation: return "Inflammation"
        case .vitamins: return "Vitamins"
        case .hormones: return "Hormones"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .cholesterol: return "drop.fill"
        case .bloodSugar: return "chart.bar.fill"
        case .liver: return "liver.fill"
        case .kidney: return "cross.vial.fill"
        case .thyroid: return "bolt.heart.fill"
        case .bloodCount: return "drop.triangle.fill"
        case .inflammation: return "flame.fill"
        case .vitamins: return "pill.fill"
        case .hormones: return "waveform.path.ecg"
        case .other: return "list.bullet.clipboard.fill"
        }
    }

    var color: Color {
        switch self {
        case .cholesterol: return .vitalyPrimary
        case .bloodSugar: return .vitalyRecovery
        case .liver: return .vitalyExcellent
        case .kidney: return .vitalySleep
        case .thyroid: return .vitalyHeart
        case .bloodCount: return .vitalyActivity
        case .inflammation: return .red
        case .vitamins: return .yellow
        case .hormones: return .cyan
        case .other: return .vitalyTextSecondary
        }
    }
}

// MARK: - Lab Value

struct LabValue: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var value: Double
    var unit: String
    var referenceMin: Double?
    var referenceMax: Double?
    var category: LabCategory

    var isOutOfRange: Bool {
        if let min = referenceMin, value < min { return true }
        if let max = referenceMax, value > max { return true }
        return false
    }

    var statusText: String {
        if let max = referenceMax, value > max { return "High" }
        if let min = referenceMin, value < min { return "Low" }
        return "Normal"
    }

    var formattedValue: String {
        if value == value.rounded() {
            return "\(Int(value)) \(unit)"
        }
        return "\(String(format: "%.1f", value)) \(unit)"
    }

    var referenceRangeText: String? {
        guard referenceMin != nil || referenceMax != nil else { return nil }
        let minStr = referenceMin.map { String(format: "%.1f", $0) } ?? "-"
        let maxStr = referenceMax.map { String(format: "%.1f", $0) } ?? "-"
        return "\(minStr) – \(maxStr) \(unit)"
    }
}

// MARK: - Health Checkup

struct HealthCheckup: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var date: Date
    var title: String
    var provider: String?
    var labValues: [LabValue]
    var aiSummary: String?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: String? = nil,
        date: Date = Date(),
        title: String = "",
        provider: String? = nil,
        labValues: [LabValue] = [],
        aiSummary: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.provider = provider
        self.labValues = labValues
        self.aiSummary = aiSummary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    var outOfRangeCount: Int {
        labValues.filter(\.isOutOfRange).count
    }

    var categories: [LabCategory] {
        let unique = Set(labValues.map(\.category))
        return LabCategory.allCases.filter { unique.contains($0) }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
