import SwiftUI

struct AuthNavigationView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var viewModel: AuthViewModel?
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            // Dark Background
            Color.vitalyBackground
                .ignoresSafeArea()

            if let viewModel = viewModel {
                if showOnboarding {
                    OnboardingView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    LoginView(viewModel: viewModel)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.3), value: showOnboarding)
        .onAppear {
            // Create view model with correct services from coordinator
            if viewModel == nil {
                viewModel = AuthViewModel(
                    authService: coordinator.authService,
                    coordinator: coordinator
                )
            }
        }
        .onChange(of: coordinator.authState) { oldValue, newValue in
            if newValue == .authenticated {
                showOnboarding = true
            }
        }
    }
}

#Preview("Auth View") {
    AuthNavigationView()
        .environmentObject(AppCoordinator())
}
