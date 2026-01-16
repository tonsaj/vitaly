import Foundation
import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    private let authService: AuthService
    private let notificationService: NotificationService

    var currentUser: User? { authService.currentUser }
    var isLoading = false
    var errorMessage: String?
    var showingSignOutConfirmation = false

    init(authService: AuthService, notificationService: NotificationService = .shared) {
        self.authService = authService
        self.notificationService = notificationService
    }

    // MARK: - Settings Updates

    func toggleNotifications() async {
        guard var settings = currentUser?.settings else { return }
        let willEnable = !settings.notificationsEnabled
        settings.notificationsEnabled = willEnable
        await updateSettings(settings)

        // Hantera notifikationsschemaläggning
        if willEnable {
            do {
                // Begär behörighet om inte redan beviljad
                if !notificationService.isAuthorized {
                    let granted = try await notificationService.requestAuthorization()
                    if !granted {
                        // Återställ om behörighet nekades
                        settings.notificationsEnabled = false
                        await updateSettings(settings)
                        errorMessage = "Notifikationsbehörighet krävs. Aktivera i Inställningar."
                        return
                    }
                }

                // Schemalägg daglig notifikation
                try await notificationService.scheduleDailyNotification()
            } catch {
                errorMessage = "Kunde inte aktivera notifikationer: \(error.localizedDescription)"
                // Återställ vid fel
                settings.notificationsEnabled = false
                await updateSettings(settings)
            }
        } else {
            // Avbryt notifikationer om inaktiverade
            notificationService.cancelDailyNotification()
        }
    }

    func toggleDailyInsights() async {
        guard var settings = currentUser?.settings else { return }
        settings.dailyInsightsEnabled.toggle()
        await updateSettings(settings)
    }

    func updateUnits(_ units: UserSettings.UnitSystem) async {
        guard var settings = currentUser?.settings else { return }
        settings.preferredUnits = units
        await updateSettings(settings)
    }

    func updateGoal<T>(_ keyPath: WritableKeyPath<HealthGoals, T>, value: T) async {
        guard var settings = currentUser?.settings else { return }
        settings.goals[keyPath: keyPath] = value
        await updateSettings(settings)
    }

    private func updateSettings(_ settings: UserSettings) async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.updateUserSettings(settings)
        } catch {
            errorMessage = "Kunde inte uppdatera inställningar: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Profile Updates

    func updateDisplayName(_ name: String) async {
        guard !name.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.updateDisplayName(name)
        } catch {
            errorMessage = "Kunde inte uppdatera namn: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() {
        authService.signOut()
    }

    // MARK: - HealthKit Permissions

    func openHealthKitSettings() {
        if let url = URL(string: "x-apple-health://") {
            UIApplication.shared.open(url)
        }
    }
}
