import SwiftUI
import Combine
import FirebaseAuth

enum AuthState: Equatable {
    case unknown
    case unauthenticated
    case authenticated
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var authState: AuthState = .unknown
    @Published var currentUser: User?

    let authService: AuthService
    private let healthKitService: HealthKitService
    private var cancellables = Set<AnyCancellable>()

    init(authService: AuthService? = nil,
         healthKitService: HealthKitService? = nil) {
        self.authService = authService ?? AuthService()
        self.healthKitService = healthKitService ?? HealthKitService()

        setupAuthStateListener()
    }

    private func setupAuthStateListener() {
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                if let user = user {
                    self?.currentUser = user
                    self?.authState = .authenticated
                } else {
                    self?.currentUser = nil
                    self?.authState = .unauthenticated
                }
            }
            .store(in: &cancellables)
    }

    func signOut() {
        authService.signOut()
    }

    func requestHealthKitPermissions() async throws {
        try await healthKitService.requestAuthorization()
    }
}
