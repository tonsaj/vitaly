import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var currentPage = 0
    @State private var healthKitRequested = false
    @State private var notificationsRequested = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let totalPages = 4

    var body: some View {
        ZStack {
            // Dark background
            Color.vitalyBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page Indicator
                pageIndicator

                // Pages
                TabView(selection: $currentPage) {
                    WelcomePage(onContinue: { currentPage = 1 })
                        .tag(0)

                    HealthKitPermissionPage(
                        isRequested: $healthKitRequested,
                        onContinue: { await requestHealthKit() }
                    )
                    .tag(1)

                    NotificationPermissionPage(
                        isRequested: $notificationsRequested,
                        onContinue: { await requestNotifications() }
                    )
                    .tag(2)

                    CompletionPage(onFinish: { /* Onboarding complete */ })
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Fel", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Page Indicator
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ?
                          LinearGradient.vitalyGradient : LinearGradient(colors: [Color.vitalySurface], startPoint: .leading, endPoint: .trailing))
                    .frame(width: index == currentPage ? 32 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    // MARK: - Helper Methods
    @MainActor
    private func requestHealthKit() async {
        do {
            try await coordinator.requestHealthKitPermissions()
            healthKitRequested = true
            currentPage = 2
        } catch {
            errorMessage = "Kunde inte begära HealthKit-behörigheter: \(error.localizedDescription)"
            showError = true
        }
    }

    @MainActor
    private func requestNotifications() async {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            notificationsRequested = true
            currentPage = 3
        } catch {
            errorMessage = "Kunde inte begära notifikationsbehörigheter: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Welcome Page
struct WelcomePage: View {
    var onContinue: () -> Void
    @State private var animateContent = false

    var body: some View {
        ZStack {
            Color.vitalyBackground
                .ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                // Animated Sunburst Icon with Gradient Background
                AnimatedSunburstLogo()
                    .frame(width: 160, height: 160)
                    .scaleEffect(animateContent ? 1.0 : 0.5)
                    .opacity(animateContent ? 1.0 : 0)

                // Text Content
                VStack(spacing: 20) {
                    Text("Välkommen till Vitaly")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1.0 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    Text("Din personliga hälsoassistent som hjälper dig att följa och förbättra din hälsa")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(4)
                        .opacity(animateContent ? 1.0 : 0)
                        .offset(y: animateContent ? 0 : 20)
                }

                // Features
                VStack(spacing: 24) {
                    FeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Spåra din hälsa",
                        description: "Följ viktiga hälsomått i realtid"
                    )
                    .opacity(animateContent ? 1.0 : 0)
                    .offset(x: animateContent ? 0 : -30)

                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "AI-insikter",
                        description: "Få personliga rekommendationer"
                    )
                    .opacity(animateContent ? 1.0 : 0)
                    .offset(x: animateContent ? 0 : -30)

                    FeatureRow(
                        icon: "bell.fill",
                        title: "Smarta påminnelser",
                        description: "Håll dig på rätt spår varje dag"
                    )
                    .opacity(animateContent ? 1.0 : 0)
                    .offset(x: animateContent ? 0 : -30)
                }
                .padding(.horizontal, 32)

                Spacer()

                // Continue Button
                Button {
                    onContinue()
                } label: {
                    Text("Kom igång")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(LinearGradient.vitalyHeroGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.vitalyPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .opacity(animateContent ? 1.0 : 0)
                .scaleEffect(animateContent ? 1.0 : 0.9)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateContent = true
            }
        }
    }
}

// MARK: - HealthKit Permission Page
struct HealthKitPermissionPage: View {
    @Binding var isRequested: Bool
    var onContinue: () async -> Void

    var body: some View {
        ZStack {
            Color.vitalyBackground
                .ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                // Icon with gradient
                ZStack {
                    Circle()
                        .fill(LinearGradient.vitalyActivityGradient)
                        .frame(width: 130, height: 130)
                        .shadow(color: Color.vitalyActivity.opacity(0.4), radius: 30, x: 0, y: 15)

                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 64, weight: .medium))
                        .foregroundStyle(.white)
                }

                // Text Content
                VStack(spacing: 16) {
                    Text("Anslut till Apple Hälsa")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Vi behöver tillgång till din hälsodata för att ge dig personliga insikter")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(4)
                }

                // Permissions
                VStack(spacing: 20) {
                    PermissionRow(
                        icon: "figure.walk",
                        title: "Aktivitet",
                        description: "Steg, distans och träningspass"
                    )

                    PermissionRow(
                        icon: "heart.fill",
                        title: "Hjärta",
                        description: "Hjärtfrekvens och variabilitet"
                    )

                    PermissionRow(
                        icon: "bed.double.fill",
                        title: "Sömn",
                        description: "Sömnanalys och kvalitet"
                    )

                    PermissionRow(
                        icon: "drop.fill",
                        title: "Vitalparametrar",
                        description: "Blodtryck och syremättnad"
                    )
                }
                .padding(.horizontal, 32)

                Spacer()

                // Privacy Note
                HStack(spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(Color.vitalyActivity)

                    Text("Din data är krypterad och privat")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.vitalyTextSecondary)
                }

                // Continue Button
                Button {
                    Task { await onContinue() }
                } label: {
                    Text(isRequested ? "Fortsätt" : "Aktivera HealthKit")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(LinearGradient.vitalyActivityGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.vitalyActivity.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Notification Permission Page
struct NotificationPermissionPage: View {
    @Binding var isRequested: Bool
    var onContinue: () async -> Void

    var body: some View {
        ZStack {
            Color.vitalyBackground
                .ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                // Icon with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.vitalyRecovery, Color.vitalyRecovery.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 130, height: 130)
                        .shadow(color: Color.vitalyRecovery.opacity(0.4), radius: 30, x: 0, y: 15)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 64, weight: .medium))
                        .foregroundStyle(.white)
                }

                // Text Content
                VStack(spacing: 16) {
                    Text("Håll dig informerad")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Få påminnelser och uppdateringar om din hälsa")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(4)
                }

                // Notification Types
                VStack(spacing: 20) {
                    NotificationRow(
                        icon: "sparkles",
                        title: "Dagliga insikter",
                        description: "Personliga hälsotips varje dag"
                    )

                    NotificationRow(
                        icon: "target",
                        title: "Målpåminnelser",
                        description: "Håll dig på rätt spår med dina mål"
                    )

                    NotificationRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Framstegsuppdateringar",
                        description: "Fira dina framsteg och milstolpar"
                    )
                }
                .padding(.horizontal, 32)

                Spacer()

                // Continue Button
                Button {
                    Task { await onContinue() }
                } label: {
                    Text(isRequested ? "Fortsätt" : "Aktivera notifikationer")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(LinearGradient.vitalyRecoveryGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.vitalyRecovery.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Completion Page
struct CompletionPage: View {
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            Color.vitalyBackground
                .ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                // Icon with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.vitalyExcellent, Color.vitalyExcellent.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .shadow(color: Color.vitalyExcellent.opacity(0.4), radius: 30, x: 0, y: 15)

                    Image(systemName: "checkmark")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundStyle(.white)
                }

                // Text Content
                VStack(spacing: 16) {
                    Text("Allt klart!")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Du är nu redo att börja din hälsoresa med oss")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(4)
                }

                // Success Items
                VStack(spacing: 24) {
                    CompletionRow(
                        icon: "checkmark.circle.fill",
                        title: "Konto skapat",
                        color: Color.vitalyExcellent
                    )

                    CompletionRow(
                        icon: "checkmark.circle.fill",
                        title: "HealthKit anslutet",
                        color: Color.vitalyExcellent
                    )

                    CompletionRow(
                        icon: "checkmark.circle.fill",
                        title: "Notifikationer aktiverade",
                        color: Color.vitalyExcellent
                    )
                }
                .padding(.horizontal, 32)

                Spacer()

                // Finish Button
                Button {
                    onFinish()
                } label: {
                    Text("Börja använda appen")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.vitalyExcellent, Color.vitalyExcellent.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.vitalyExcellent.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Supporting Views
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.vitalyPrimary.opacity(0.15))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.vitalyPrimary, Color.vitalySecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text(description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.vitalyTextSecondary)
            }

            Spacer()
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.vitalyActivity.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.vitalyActivity)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.vitalyTextSecondary)
            }

            Spacer()
        }
    }
}

struct NotificationRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.vitalyRecovery.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.vitalyRecovery)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.vitalyTextSecondary)
            }

            Spacer()
        }
    }
}

struct CompletionRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.vitalyTextPrimary)

            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppCoordinator())
}
