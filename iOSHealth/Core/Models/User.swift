import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    let phoneNumber: String
    var email: String?
    var displayName: String?
    var photoURL: String?
    let createdAt: Date
    var settings: UserSettings
    var birthDate: Date?
    var heightCm: Double?

    init(id: String? = nil,
         phoneNumber: String = "",
         email: String? = nil,
         displayName: String? = nil,
         photoURL: String? = nil,
         createdAt: Date = Date(),
         settings: UserSettings = UserSettings(),
         birthDate: Date? = nil,
         heightCm: Double? = nil) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.settings = settings
        self.birthDate = birthDate
        self.heightCm = heightCm
    }

    var age: Int? {
        guard let birthDate = birthDate else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year
    }
}

struct UserSettings: Codable, Equatable {
    var notificationsEnabled: Bool = true
    var dailyInsightsEnabled: Bool = true
    var preferredUnits: UnitSystem = .metric
    var goals: HealthGoals = HealthGoals()

    enum UnitSystem: String, Codable {
        case metric
        case imperial
    }
}

struct HealthGoals: Codable, Equatable {
    var dailySteps: Int = 10000
    var sleepHours: Double = 8.0
    var exerciseMinutes: Int = 30
    var activeCalories: Int = 500

    static let defaultGoals = HealthGoals()

    // Steg-alternativ för picker
    static let stepsOptions = [5000, 6000, 7000, 8000, 9000, 10000, 12000, 15000, 20000]
    // Sömn-alternativ för picker
    static let sleepOptions: [Double] = [5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10]
    // Träningsminuter-alternativ för picker
    static let exerciseOptions = [15, 20, 30, 45, 60, 90, 120]
    // Aktiva kalorier-alternativ för picker
    static let caloriesOptions = [200, 300, 400, 500, 600, 700, 800, 1000]
}
