import Foundation
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

@Observable
final class GLP1Service {
    var treatment: GLP1Treatment?
    var medicationLogs: [MedicationLog] = []
    var sideEffectLogs: [SideEffectLog] = []
    var bodyCompositions: [BodyComposition] = []
    var isLoading = false
    var error: String?

    private let db = Firestore.firestore()
    private var userId: String?

    // MARK: - User Management

    func setUserId(_ userId: String?) {
        self.userId = userId
        if userId != nil {
            Task {
                await fetchAllData()
            }
        } else {
            clearData()
        }
    }

    private func clearData() {
        treatment = nil
        medicationLogs = []
        sideEffectLogs = []
        bodyCompositions = []
    }

    // MARK: - Fetch All Data

    @MainActor
    func fetchAllData() async {
        guard let userId = userId else { return }
        isLoading = true
        error = nil

        async let treatmentTask: () = fetchTreatment()
        async let logsTask: () = fetchMedicationLogs(limit: 52) // Last year
        async let sideEffectsTask: () = fetchSideEffectLogs(limit: 90) // Last 90 days
        async let bodyCompTask: () = fetchBodyCompositions(limit: 52)

        _ = await (treatmentTask, logsTask, sideEffectsTask, bodyCompTask)

        isLoading = false
    }

    // MARK: - Treatment

    @MainActor
    func fetchTreatment() async {
        guard let userId = userId else { return }

        do {
            let doc = try await db.collection("users").document(userId)
                .collection("glp1Treatment").document("current").getDocument()

            if doc.exists, let data = doc.data() {
                treatment = try? Firestore.Decoder().decode(GLP1Treatment.self, from: data)
            }
        } catch {
            print("Error fetching treatment: \(error)")
            self.error = error.localizedDescription
        }
    }

    @MainActor
    func saveTreatment(_ treatment: GLP1Treatment) async throws {
        guard let userId = userId else { throw GLP1Error.notAuthenticated }

        let data = try Firestore.Encoder().encode(treatment)
        try await db.collection("users").document(userId)
            .collection("glp1Treatment").document("current").setData(data)

        self.treatment = treatment

        // Schedule notifications if enabled
        if treatment.notificationsEnabled && treatment.isActive {
            await scheduleInjectionReminder(for: treatment)
        } else {
            cancelInjectionReminders()
        }
    }

    // MARK: - Notification Scheduling

    private let notificationIdentifier = "glp1-injection-reminder"

    /// Schedule injection reminder notification
    func scheduleInjectionReminder(for treatment: GLP1Treatment) async {
        // Request notification permission
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                print("⚠️ GLP-1: Notification permission denied")
                return
            }
        } catch {
            print("❌ GLP-1: Failed to request notification permission: \(error)")
            return
        }

        // Cancel existing reminders
        cancelInjectionReminders()

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "💉 Injection Reminder"
        content.body = "Time for your \(treatment.medication.displayName) injection (\(String(format: "%.2g", treatment.currentDose)) mg)"
        content.sound = .default
        content.categoryIdentifier = "GLP1_INJECTION"

        // Create trigger based on medication type
        var trigger: UNNotificationTrigger

        if treatment.medication.isWeekly {
            // Weekly medication - schedule for preferred day and time
            var dateComponents = DateComponents()
            dateComponents.weekday = (treatment.preferredInjectionDay ?? 1) + 1 // Convert 1-7 Mon-Sun to 1-7 Sun-Sat
            if dateComponents.weekday! > 7 { dateComponents.weekday = 1 }
            dateComponents.hour = treatment.preferredInjectionHour
            dateComponents.minute = treatment.preferredInjectionMinute

            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        } else {
            // Daily medication - schedule for preferred time every day
            var dateComponents = DateComponents()
            dateComponents.hour = treatment.preferredInjectionHour
            dateComponents.minute = treatment.preferredInjectionMinute

            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        }

        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            print("✅ GLP-1: Scheduled injection reminder")
        } catch {
            print("❌ GLP-1: Failed to schedule notification: \(error)")
        }
    }

    /// Cancel all injection reminder notifications
    func cancelInjectionReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        print("🗑️ GLP-1: Cancelled injection reminders")
    }

    /// Toggle notifications on/off
    @MainActor
    func toggleNotifications(_ enabled: Bool) async throws {
        guard var treatment = treatment else { throw GLP1Error.noTreatment }

        treatment.notificationsEnabled = enabled
        try await saveTreatment(treatment)
    }

    @MainActor
    func updateDose(_ newDose: Double) async throws {
        guard var treatment = treatment else { throw GLP1Error.noTreatment }

        treatment.currentDose = newDose
        treatment.currentDoseStartDate = Date()

        try await saveTreatment(treatment)
    }

    @MainActor
    func stopTreatment() async throws {
        guard var treatment = treatment else { throw GLP1Error.noTreatment }

        treatment.isActive = false
        try await saveTreatment(treatment)
    }

    // MARK: - Medication Logs

    @MainActor
    func fetchMedicationLogs(limit: Int = 52) async {
        guard let userId = userId else { return }

        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("medicationLogs")
                .order(by: "date", descending: true)
                .limit(to: limit)
                .getDocuments()

            medicationLogs = snapshot.documents.compactMap { doc in
                try? Firestore.Decoder().decode(MedicationLog.self, from: doc.data())
            }
        } catch {
            print("Error fetching medication logs: \(error)")
        }
    }

    @MainActor
    func logMedication(_ log: MedicationLog) async throws {
        guard let userId = userId else { throw GLP1Error.notAuthenticated }

        let data = try Firestore.Encoder().encode(log)
        try await db.collection("users").document(userId)
            .collection("medicationLogs").document(log.id).setData(data)

        // Insert at beginning since sorted by date desc
        medicationLogs.insert(log, at: 0)
    }

    @MainActor
    func deleteMedicationLog(_ log: MedicationLog) async throws {
        guard let userId = userId else { throw GLP1Error.notAuthenticated }

        try await db.collection("users").document(userId)
            .collection("medicationLogs").document(log.id).delete()

        medicationLogs.removeAll { $0.id == log.id }
    }

    var lastInjectionDate: Date? {
        medicationLogs.first(where: { !$0.skipped })?.date
    }

    var daysSinceLastInjection: Int? {
        guard let lastDate = lastInjectionDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
    }

    var isInjectionDue: Bool {
        guard let treatment = treatment, treatment.medication.isWeekly else { return false }
        guard let days = daysSinceLastInjection else { return true }
        return days >= 7
    }

    // MARK: - Side Effect Logs

    @MainActor
    func fetchSideEffectLogs(limit: Int = 90) async {
        guard let userId = userId else { return }

        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("sideEffectLogs")
                .order(by: "date", descending: true)
                .limit(to: limit)
                .getDocuments()

            sideEffectLogs = snapshot.documents.compactMap { doc in
                try? Firestore.Decoder().decode(SideEffectLog.self, from: doc.data())
            }
        } catch {
            print("Error fetching side effect logs: \(error)")
        }
    }

    @MainActor
    func logSideEffects(_ log: SideEffectLog) async throws {
        guard let userId = userId else { throw GLP1Error.notAuthenticated }

        let data = try Firestore.Encoder().encode(log)
        try await db.collection("users").document(userId)
            .collection("sideEffectLogs").document(log.id).setData(data)

        sideEffectLogs.insert(log, at: 0)
    }

    var averageNausea: Double {
        guard !sideEffectLogs.isEmpty else { return 0 }
        let recent = Array(sideEffectLogs.prefix(7))
        return Double(recent.map(\.nausea).reduce(0, +)) / Double(recent.count)
    }

    var averageEnergy: Double {
        guard !sideEffectLogs.isEmpty else { return 5 }
        let recent = Array(sideEffectLogs.prefix(7))
        return Double(recent.map(\.energy).reduce(0, +)) / Double(recent.count)
    }

    // MARK: - Body Composition

    @MainActor
    func fetchBodyCompositions(limit: Int = 52) async {
        guard let userId = userId else { return }

        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("bodyCompositions")
                .order(by: "date", descending: true)
                .limit(to: limit)
                .getDocuments()

            bodyCompositions = snapshot.documents.compactMap { doc in
                try? Firestore.Decoder().decode(BodyComposition.self, from: doc.data())
            }
        } catch {
            print("Error fetching body compositions: \(error)")
        }
    }

    @MainActor
    func logBodyComposition(_ comp: BodyComposition) async throws {
        guard let userId = userId else { throw GLP1Error.notAuthenticated }

        let data = try Firestore.Encoder().encode(comp)
        try await db.collection("users").document(userId)
            .collection("bodyCompositions").document(comp.id).setData(data)

        bodyCompositions.insert(comp, at: 0)
    }

    var latestBodyComposition: BodyComposition? {
        bodyCompositions.first
    }

    var muscleMassChange: Double? {
        guard bodyCompositions.count >= 2 else { return nil }
        guard let latest = bodyCompositions.first?.muscleMass,
              let previous = bodyCompositions.dropFirst().first?.muscleMass else { return nil }
        return latest - previous
    }

    // MARK: - Weight Loss Stats

    func getWeightLossStats(currentWeight: Double) -> WeightLossStats? {
        guard let treatment = treatment else { return nil }

        return WeightLossStats(
            startWeight: treatment.startWeight,
            currentWeight: currentWeight,
            targetWeight: treatment.targetWeight,
            weeksOnTreatment: treatment.weeksOnTreatment
        )
    }
}

// MARK: - Errors

enum GLP1Error: LocalizedError {
    case notAuthenticated
    case noTreatment
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to use this feature"
        case .noTreatment:
            return "No active treatment found"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}
