import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let phoneNumber: String
    var displayName: String?
    var photoURL: String?
    let createdAt: Date
    var settings: UserSettings

    init(id: String? = nil,
         phoneNumber: String,
         displayName: String? = nil,
         photoURL: String? = nil,
         createdAt: Date = Date(),
         settings: UserSettings = UserSettings()) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.settings = settings
    }
}

struct UserSettings: Codable, Equatable {
    var notificationsEnabled: Bool = true
    var dailyInsightsEnabled: Bool = true
    var preferredUnits: UnitSystem = .metric

    enum UnitSystem: String, Codable {
        case metric
        case imperial
    }
}
