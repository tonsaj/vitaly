import Foundation
import FirebaseFirestore

// MARK: - GLP-1 Medication Types

enum GLP1Medication: String, Codable, CaseIterable {
    case ozempic = "ozempic"
    case wegovy = "wegovy"
    case mounjaro = "mounjaro"
    case saxenda = "saxenda"
    case rybelsus = "rybelsus"

    var displayName: String {
        switch self {
        case .ozempic: return "Ozempic"
        case .wegovy: return "Wegovy"
        case .mounjaro: return "Mounjaro"
        case .saxenda: return "Saxenda"
        case .rybelsus: return "Rybelsus"
        }
    }

    var manufacturer: String {
        switch self {
        case .ozempic, .wegovy, .saxenda, .rybelsus: return "Novo Nordisk"
        case .mounjaro: return "Eli Lilly"
        }
    }

    var activeIngredient: String {
        switch self {
        case .ozempic, .wegovy, .rybelsus: return "Semaglutide"
        case .mounjaro: return "Tirzepatide"
        case .saxenda: return "Liraglutide"
        }
    }

    /// Standard dose escalation schedule (in mg)
    var doseSchedule: [Double] {
        switch self {
        case .ozempic:
            return [0.25, 0.5, 1.0, 2.0]
        case .wegovy:
            return [0.25, 0.5, 1.0, 1.7, 2.4]
        case .mounjaro:
            return [2.5, 5.0, 7.5, 10.0, 12.5, 15.0]
        case .saxenda:
            return [0.6, 1.2, 1.8, 2.4, 3.0]
        case .rybelsus:
            return [3.0, 7.0, 14.0]
        }
    }

    /// Weeks per dose level before escalation
    var weeksPerDose: Int {
        switch self {
        case .ozempic, .wegovy, .mounjaro: return 4
        case .saxenda: return 1
        case .rybelsus: return 4
        }
    }

    /// Dose unit
    var unit: String {
        return "mg"
    }

    /// Is it a weekly or daily medication
    var isWeekly: Bool {
        switch self {
        case .ozempic, .wegovy, .mounjaro: return true
        case .saxenda, .rybelsus: return false
        }
    }
}

// MARK: - Treatment Model

struct GLP1Treatment: Codable, Identifiable {
    var id: String = UUID().uuidString
    var medication: GLP1Medication
    var startDate: Date
    var startWeight: Double
    var targetWeight: Double?
    var currentDose: Double
    var currentDoseStartDate: Date
    var preferredInjectionDay: Int? // 1-7 (Monday-Sunday) for weekly meds
    var preferredInjectionHour: Int = 9 // Default 09:00
    var preferredInjectionMinute: Int = 0
    var notificationsEnabled: Bool = true
    var notes: String?
    var isActive: Bool = true

    // Computed properties
    var weeksOnTreatment: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: startDate, to: Date())
        return max(0, components.weekOfYear ?? 0)
    }

    var weeksOnCurrentDose: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: currentDoseStartDate, to: Date())
        return max(0, components.weekOfYear ?? 0)
    }

    var currentDoseIndex: Int {
        medication.doseSchedule.firstIndex(of: currentDose) ?? 0
    }

    var nextDose: Double? {
        let nextIndex = currentDoseIndex + 1
        guard nextIndex < medication.doseSchedule.count else { return nil }
        return medication.doseSchedule[nextIndex]
    }

    var isReadyForDoseIncrease: Bool {
        weeksOnCurrentDose >= medication.weeksPerDose && nextDose != nil
    }

    var isAtMaxDose: Bool {
        currentDose == medication.doseSchedule.last
    }

    /// Next injection day for weekly medications
    var nextInjectionDate: Date? {
        guard medication.isWeekly else { return nil }
        guard let preferredDay = preferredInjectionDay else { return nil }

        let calendar = Calendar.current
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)

        // Convert to 1-7 Monday-Sunday format
        let adjustedCurrentDay = currentWeekday == 1 ? 7 : currentWeekday - 1

        var daysUntilNext = preferredDay - adjustedCurrentDay
        if daysUntilNext <= 0 {
            daysUntilNext += 7
        }

        return calendar.date(byAdding: .day, value: daysUntilNext, to: today)
    }
}

// MARK: - Medication Log

struct MedicationLog: Codable, Identifiable {
    var id: String = UUID().uuidString
    var date: Date
    var dose: Double
    var medication: GLP1Medication
    var injectionSite: InjectionSite?
    var notes: String?
    var skipped: Bool = false
    var skipReason: String?

    enum InjectionSite: String, Codable, CaseIterable {
        case abdomen = "abdomen"
        case thigh = "thigh"
        case upperArm = "upper_arm"

        var displayName: String {
            switch self {
            case .abdomen: return "Abdomen"
            case .thigh: return "Thigh"
            case .upperArm: return "Upper Arm"
            }
        }

        var icon: String {
            switch self {
            case .abdomen: return "figure.stand"
            case .thigh: return "figure.walk"
            case .upperArm: return "figure.arms.open"
            }
        }
    }
}

// MARK: - Side Effect Log

struct SideEffectLog: Codable, Identifiable {
    var id: String = UUID().uuidString
    var date: Date
    var nausea: Int // 1-10
    var appetite: Int // 1-10 (1 = no appetite, 10 = very hungry)
    var energy: Int // 1-10
    var constipation: Int? // 1-10
    var diarrhea: Int? // 1-10
    var headache: Int? // 1-10
    var fatigue: Int? // 1-10
    var notes: String?

    var overallWellbeing: Double {
        let scores = [
            10 - nausea, // Invert nausea (low nausea = good)
            energy,
            10 - (constipation ?? 0),
            10 - (diarrhea ?? 0),
            10 - (headache ?? 0),
            10 - (fatigue ?? 0)
        ].filter { $0 > 0 }

        guard !scores.isEmpty else { return 5.0 }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }
}

// MARK: - Body Composition

struct BodyComposition: Codable, Identifiable {
    var id: String = UUID().uuidString
    var date: Date
    var weight: Double
    var bodyFatPercentage: Double?
    var muscleMass: Double?
    var boneMass: Double?
    var waterPercentage: Double?
    var visceralFat: Int?
    var metabolicAge: Int?
    var bmi: Double?

    /// Calculated lean mass
    var leanMass: Double? {
        guard let fatPct = bodyFatPercentage else { return nil }
        return weight * (1 - fatPct / 100)
    }

    /// Calculated fat mass
    var fatMass: Double? {
        guard let fatPct = bodyFatPercentage else { return nil }
        return weight * (fatPct / 100)
    }
}

// MARK: - Weight Loss Stats

struct WeightLossStats {
    let startWeight: Double
    let currentWeight: Double
    let targetWeight: Double?
    let weeksOnTreatment: Int

    var totalLost: Double {
        startWeight - currentWeight
    }

    var percentageLost: Double {
        guard startWeight > 0 else { return 0 }
        return (totalLost / startWeight) * 100
    }

    var weeklyAverage: Double {
        guard weeksOnTreatment > 0 else { return 0 }
        return totalLost / Double(weeksOnTreatment)
    }

    var remainingToTarget: Double? {
        guard let target = targetWeight else { return nil }
        return currentWeight - target
    }

    var progressToTarget: Double? {
        guard let target = targetWeight else { return nil }
        let totalToLose = startWeight - target
        guard totalToLose > 0 else { return nil }
        return (totalLost / totalToLose) * 100
    }

    /// Warning if losing too fast (>1kg/week average)
    var isLosingTooFast: Bool {
        weeklyAverage > 1.0
    }

    /// Warning if losing too slow (<0.25kg/week after 4+ weeks)
    var isLosingTooSlow: Bool {
        weeksOnTreatment >= 4 && weeklyAverage < 0.25
    }

    var statusMessage: String {
        if isLosingTooFast {
            return "Weight loss is rapid - consider consulting your doctor"
        } else if isLosingTooSlow {
            return "Weight loss is slow - dose adjustment may help"
        } else {
            return "Weight loss is on track"
        }
    }

    var statusColor: String {
        if isLosingTooFast {
            return "warning"
        } else if isLosingTooSlow {
            return "secondary"
        } else {
            return "success"
        }
    }
}
