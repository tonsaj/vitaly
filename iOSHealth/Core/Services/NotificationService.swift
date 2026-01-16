import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized: Bool = false
    private let notificationCenter = UNUserNotificationCenter.current()

    // Notification identifier
    private let dailySummaryIdentifier = "daily-health-summary"

    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Permission Management

    /// Kontrollera aktuell behörighetsstatus
    func checkAuthorizationStatus() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            await MainActor.run {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    /// Begär behörighet för notifikationer
    func requestAuthorization() async throws -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            await MainActor.run {
                self.isAuthorized = granted
            }

            if granted {
                print("📲 Notifikationsbehörighet beviljad")
            } else {
                print("⚠️ Notifikationsbehörighet nekad")
            }

            return granted
        } catch {
            print("❌ Fel vid begäran av notifikationsbehörighet: \(error.localizedDescription)")
            throw NotificationError.authorizationFailed
        }
    }

    // MARK: - Daily Notification Scheduling

    /// Schemalägg daglig notifikation kl 22:00
    func scheduleDailyNotification() async throws {
        // Kontrollera behörighet först
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            throw NotificationError.notAuthorized
        }

        // Ta bort eventuella tidigare schemalagda notifikationer
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [dailySummaryIdentifier]
        )

        // Skapa notifikationsinnehåll
        let content = UNMutableNotificationContent()
        content.title = "Dagens sammanfattning"
        content.body = "Så här såg din dag ut. Bra jobbat! 💪"
        content.sound = .default
        content.badge = 1

        // Lägg till kategori för interaktiva åtgärder (framtida utökning)
        content.categoryIdentifier = "DAILY_SUMMARY"

        // Konfigurera trigger för 22:00 varje dag
        var dateComponents = DateComponents()
        dateComponents.hour = 22
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        // Skapa notifikationsbegäran
        let request = UNNotificationRequest(
            identifier: dailySummaryIdentifier,
            content: content,
            trigger: trigger
        )

        // Lägg till notifikationen
        try await notificationCenter.add(request)

        print("✅ Daglig notifikation schemalagd för 22:00")
    }

    /// Schemalägg daglig notifikation med AI-genererat innehåll
    func scheduleDailyNotificationWithAI(
        sleep: SleepData?,
        activity: ActivityData?,
        heart: HeartData?
    ) async throws {
        // Kontrollera behörighet först
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            throw NotificationError.notAuthorized
        }

        // Ta bort eventuella tidigare schemalagda notifikationer
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [dailySummaryIdentifier]
        )

        // Generera AI-innehåll
        let notificationBody = try await generateNotificationContent(
            sleep: sleep,
            activity: activity,
            heart: heart
        )

        // Skapa notifikationsinnehåll
        let content = UNMutableNotificationContent()
        content.title = "Dagens sammanfattning"
        content.body = notificationBody
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "DAILY_SUMMARY"

        // Konfigurera trigger för 22:00 varje dag
        var dateComponents = DateComponents()
        dateComponents.hour = 22
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        // Skapa notifikationsbegäran
        let request = UNNotificationRequest(
            identifier: dailySummaryIdentifier,
            content: content,
            trigger: trigger
        )

        // Lägg till notifikationen
        try await notificationCenter.add(request)

        print("✅ Daglig AI-notifikation schemalagd för 22:00")
    }

    // MARK: - AI Content Generation

    /// Generera notifikationsinnehåll med AI
    private func generateNotificationContent(
        sleep: SleepData?,
        activity: ActivityData?,
        heart: HeartData?
    ) async throws -> String {
        let prompt = buildNotificationPrompt(
            sleep: sleep,
            activity: activity,
            heart: heart
        )

        do {
            let aiContent = try await GeminiService.shared.generateContent(prompt: prompt)
            // Begränsa till max 178 tecken för notifikationer
            return String(aiContent.prefix(178))
        } catch {
            print("⚠️ Kunde inte generera AI-innehåll, använder fallback: \(error.localizedDescription)")
            return generateFallbackContent(sleep: sleep, activity: activity, heart: heart)
        }
    }

    /// Bygg prompt för notifikationsinnehåll
    private func buildNotificationPrompt(
        sleep: SleepData?,
        activity: ActivityData?,
        heart: HeartData?
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "sv_SE")
        dateFormatter.dateFormat = "EEEE"
        let dayName = dateFormatter.string(from: Date())

        var prompt = """
        Du är en uppmuntrande hälsocoach. Skapa en MYCKET KORT sammanfattning av dagens hälsa på svenska.

        VIKTIGT:
        - Max 2 korta meningar (totalt max 178 tecken)
        - Fokusera på det viktigaste höjdpunkten
        - Avsluta med uppmuntran för imorgon
        - Använd max 1 emoji
        - Skriv direkt innehållet utan intro eller förklaringar

        DAGENS DATA (\(dayName)):
        """

        if let sleep = sleep, sleep.totalHours > 0 {
            prompt += "\n- Sömn: \(String(format: "%.1f", sleep.totalHours))h (\(sleep.quality.displayText))"
        }

        if let activity = activity {
            if activity.steps > 0 {
                prompt += "\n- Steg: \(activity.steps)"
            }
            if activity.exerciseMinutes > 0 {
                prompt += "\n- Träning: \(activity.exerciseMinutes) min"
            }
        }

        if let heart = heart {
            if heart.restingHeartRate > 0 {
                prompt += "\n- Vilopuls: \(Int(heart.restingHeartRate)) bpm"
            }
            if let hrv = heart.hrv, hrv > 0 {
                prompt += "\n- HRV: \(Int(hrv)) ms"
            }
        }

        prompt += "\n\nGe en kort, positiv sammanfattning och uppmuntran för imorgon."

        return prompt
    }

    /// Fallback-innehåll om AI inte fungerar
    private func generateFallbackContent(
        sleep: SleepData?,
        activity: ActivityData?,
        heart: HeartData?
    ) -> String {
        var highlights: [String] = []

        // Sömn
        if let sleep = sleep, sleep.totalHours > 0 {
            if sleep.totalHours >= 7 {
                highlights.append("Bra sömn")
            } else {
                highlights.append("\(String(format: "%.1f", sleep.totalHours))h sömn")
            }
        }

        // Aktivitet
        if let activity = activity {
            if activity.steps >= 10000 {
                highlights.append("\(activity.steps) steg")
            } else if activity.exerciseMinutes >= 30 {
                highlights.append("\(activity.exerciseMinutes) min träning")
            }
        }

        // Hjärta
        if let heart = heart {
            if let hrv = heart.hrv, hrv >= 50 {
                highlights.append("Utmärkt återhämtning")
            } else if heart.restingHeartRate > 0 && heart.restingHeartRate < 60 {
                highlights.append("Stark hjärthälsa")
            }
        }

        if highlights.isEmpty {
            return "Bra jobbat idag! Imorgon blir ännu bättre 💪"
        } else {
            let summary = highlights.joined(separator: " • ")
            return "\(summary). Fortsätt så! 💪"
        }
    }

    // MARK: - Notification Management

    /// Avbryt alla schemalagda notifikationer
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("🔕 Alla notifikationer avbrutna")
    }

    /// Avbryt daglig sammanfattningsnotifikation
    func cancelDailyNotification() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [dailySummaryIdentifier]
        )
        print("🔕 Daglig notifikation avbruten")
    }

    /// Hämta alla väntande notifikationer (för debugging)
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }

    /// Kontrollera om daglig notifikation är schemalagd
    func isDailyNotificationScheduled() async -> Bool {
        let pending = await getPendingNotifications()
        return pending.contains { $0.identifier == dailySummaryIdentifier }
    }

    // MARK: - Test Notification

    /// Skicka en testnotifikation omedelbart (för utveckling)
    func sendTestNotification() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Testnotifikation"
        content.body = "Detta är en test av notifikationssystemet 🔔"
        content.sound = .default

        // Trigger efter 5 sekunder
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 5,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "test-notification",
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        print("📨 Testnotifikation skickad (kommer om 5 sekunder)")
    }

    /// Skicka daglig sammanfattning nu (för testning)
    func sendDailySummaryNow(
        sleep: SleepData?,
        activity: ActivityData?,
        heart: HeartData?
    ) async throws {
        let notificationBody = try await generateNotificationContent(
            sleep: sleep,
            activity: activity,
            heart: heart
        )

        let content = UNMutableNotificationContent()
        content.title = "Dagens sammanfattning"
        content.body = notificationBody
        content.sound = .default
        content.badge = 1

        // Trigger efter 2 sekunder
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 2,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "test-daily-summary",
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        print("📨 Daglig sammanfattning skickad (kommer om 2 sekunder)")
    }
}

// MARK: - Notification Errors

enum NotificationError: LocalizedError {
    case notAuthorized
    case authorizationFailed
    case schedulingFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notifikationsbehörighet krävs"
        case .authorizationFailed:
            return "Kunde inte få notifikationsbehörighet"
        case .schedulingFailed:
            return "Kunde inte schemalägga notifikation"
        }
    }
}
