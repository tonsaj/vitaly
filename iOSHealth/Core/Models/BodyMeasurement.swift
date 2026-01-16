import Foundation
import FirebaseFirestore

struct BodyMeasurement: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let date: Date
    var weight: Double? // kg
    var waistCircumference: Double? // cm
    let createdAt: Date
    var updatedAt: Date

    init(id: String? = nil,
         date: Date = Date(),
         weight: Double? = nil,
         waistCircumference: Double? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.date = date
        self.weight = weight
        self.waistCircumference = waistCircumference
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    var formattedWeight: String? {
        guard let weight = weight else { return nil }
        return String(format: "%.1f kg", weight)
    }

    var formattedWaist: String? {
        guard let waist = waistCircumference else { return nil }
        return String(format: "%.0f cm", waist)
    }
}
