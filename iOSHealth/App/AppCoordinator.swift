import SwiftUI
import Combine
import FirebaseAuth
import HealthKit

enum AuthState: Equatable {
    case unknown
    case unauthenticated
    case onboarding
    case authenticated
    case guest
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var authState: AuthState = .unknown
    @Published var currentUser: User?

    let authService: AuthService
    let bodyMeasurementService: BodyMeasurementService
    let healthKitService: HealthKitService
    let notificationService: NotificationService
    let glp1Service: GLP1Service
    private var cancellables = Set<AnyCancellable>()

    init(authService: AuthService? = nil,
         healthKitService: HealthKitService? = nil,
         bodyMeasurementService: BodyMeasurementService? = nil,
         notificationService: NotificationService? = nil,
         glp1Service: GLP1Service? = nil) {
        self.authService = authService ?? AuthService()
        self.healthKitService = healthKitService ?? HealthKitService()
        self.bodyMeasurementService = bodyMeasurementService ?? BodyMeasurementService()
        self.notificationService = notificationService ?? NotificationService.shared
        self.glp1Service = glp1Service ?? GLP1Service()

        setupAuthStateListener()
    }

    private func setupAuthStateListener() {
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self = self else { return }

                if let user = user {
                    self.currentUser = user
                    let safeUserId = user.id ?? user.phoneNumber
                    self.bodyMeasurementService.setUserId(safeUserId)
                    self.glp1Service.setUserId(safeUserId)

                    // Check if user has completed onboarding using UserDefaults
                    let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding_\(safeUserId)")
                    print("🔑 User ID: \(safeUserId), hasCompletedOnboarding: \(hasCompletedOnboarding)")

                    if !hasCompletedOnboarding {
                        // New user - show onboarding
                        self.authState = .onboarding
                    } else {
                        self.authState = .authenticated

                        // Begär notifikationsbehörighet och schemalägg daglig notifikation
                        Task {
                            await self.setupDailyNotifications()
                        }
                    }
                } else {
                    self.currentUser = nil
                    self.authState = .unauthenticated
                    self.bodyMeasurementService.setUserId(nil)
                    self.glp1Service.setUserId(nil)
                }
            }
            .store(in: &cancellables)
    }

    func signOut() {
        authService.signOut()
        authState = .unauthenticated
    }

    func continueAsGuest() {
        authState = .guest
    }

    func completeOnboarding() {
        // Mark onboarding as completed for this user
        let safeUserId = currentUser?.id ?? currentUser?.phoneNumber ?? ""
        if !safeUserId.isEmpty {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding_\(safeUserId)")
            print("✅ Onboarding completed for user: \(safeUserId)")
        }

        authState = .authenticated

        // Schemalägg notifikationer när onboarding är klar
        Task {
            await setupDailyNotifications()
        }
    }

    func requestHealthKitPermissions() async throws {
        try await healthKitService.requestAuthorization()
    }

    // MARK: - Notification Setup

    /// Sätt upp dagliga notifikationer
    func setupDailyNotifications() async {
        do {
            // Begär behörighet om inte redan beviljad
            if !notificationService.isAuthorized {
                let granted = try await notificationService.requestAuthorization()
                if !granted {
                    print("⚠️ Notifikationer nekades av användaren")
                    return
                }
            }

            // Schemalägg daglig notifikation kl 22:00
            try await notificationService.scheduleDailyNotification()

        } catch {
            print("❌ Kunde inte schemalägga notifikationer: \(error.localizedDescription)")
        }
    }

    /// Uppdatera daglig notifikation med dagens hälsodata (anropas från Dashboard)
    func updateDailyNotificationWithHealthData(
        sleep: SleepData?,
        activity: ActivityData?,
        heart: HeartData?
    ) async {
        do {
            guard notificationService.isAuthorized else { return }
            try await notificationService.scheduleDailyNotificationWithAI(
                sleep: sleep,
                activity: activity,
                heart: heart
            )
        } catch {
            print("⚠️ Kunde inte uppdatera AI-notifikation: \(error.localizedDescription)")
        }
    }
}
