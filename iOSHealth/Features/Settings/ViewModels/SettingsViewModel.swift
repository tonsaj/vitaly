import Foundation
import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    private let authService: AuthService

    var currentUser: User? { authService.currentUser }
    var isLoading = false
    var errorMessage: String?
    var showingSignOutConfirmation = false

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Settings Updates

    func toggleNotifications() async {
        guard var settings = currentUser?.settings else { return }
        settings.notificationsEnabled.toggle()
        await updateSettings(settings)
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
