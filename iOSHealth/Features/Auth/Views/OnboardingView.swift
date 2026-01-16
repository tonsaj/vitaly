import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var currentPage = 0
    @State private var healthKitRequested = false
    @State private var notificationsRequested = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
    @State private var heightCm: Double = 170
    @State private var disclaimerAccepted = false

    private let totalPages = 6

    var body: some View {
        ZStack {
            // Dark background
            Color.vitalyBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page Indicator
                pageIndicator

                // Pages - No swiping allowed, must use buttons
                Group {
                    switch currentPage {
                    case 0:
                        WelcomePage(onContinue: { currentPage = 1 })
                    case 1:
                        HealthKitPermissionPage(
                            isRequested: $healthKitRequested,
                            onContinue: { await requestHealthKit() }
                        )
                    case 2:
                        NotificationPermissionPage(
                            isRequested: $notificationsRequested,
                            onContinue: { await requestNotifications() }
                        )
                    case 3:
                        ProfileSetupPage(
                            birthDate: $birthDate,
                            heightCm: $heightCm,
                            onContinue: { await saveProfile() }
                        )
                    case 4:
                        MedicalDisclaimerPage(
                            isAccepted: $disclaimerAccepted,
                            onContinue: { currentPage = 5 }
                        )
                    case 5:
                        CompletionPage(onFinish: { coordinator.completeOnboarding() })
                    default:
                        WelcomePage(onContinue: { currentPage = 1 })
                    }
                }
                .animation(.easeInOut, value: currentPage)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: $showError) {
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
            errorMessage = "Could not request HealthKit permissions: \(error.localizedDescription)"
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
            errorMessage = "Could not request notification permissions: \(error.localizedDescription)"
            showError = true
        }
    }

    @MainActor
    private func saveProfile() async {
        do {
            try await coordinator.authService.updateBirthDate(birthDate)
            try await coordinator.authService.updateHeight(heightCm)
            currentPage = 4 // Go to disclaimer page
        } catch {
            errorMessage = "Could not save profile: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Medical Disclaimer Page
struct MedicalDisclaimerPage: View {
    @Binding var isAccepted: Bool
    var onContinue: () -> Void
    @State private var animateContent = false

    var body: some View {
        ZStack {
            Color.vitalyBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Animated Wave Header
                        OnboardingWaveHeader(
                            gradientColors: [Color.vitalyHeart, Color.vitalyPrimary, Color.vitalySecondary]
                        ) {
                            VStack(spacing: 16) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 100, height: 100)

                                    Image(systemName: "exclamationmark.shield.fill")
                                        .font(.system(size: 50, weight: .medium))
                                        .foregroundStyle(.white)
                                }

                                VStack(spacing: 8) {
                                    Text("Important Notice")
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.vitalyTextPrimary)
                                        .multilineTextAlignment(.center)

                                    Text("Please read and accept before continuing")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(3)
                                        .padding(.horizontal, 24)
                                }
                            }
                        }

                        // Disclaimer Content
                        VStack(spacing: 20) {
                            // AI Generated Notice
                            DisclaimerCard(
                                icon: "brain.head.profile",
                                title: "AI-Generated Insights",
                                description: "All health insights, recommendations, and analysis in this app are generated by artificial intelligence. While we strive for accuracy, AI can make mistakes.",
                                color: Color.vitalyPrimary
                            )
                            .opacity(animateContent ? 1.0 : 0)
                            .offset(y: animateContent ? 0 : 20)

                            // Not Medical Advice
                            DisclaimerCard(
                                icon: "stethoscope",
                                title: "Not Medical Advice",
                                description: "The information provided by Vitaly is for informational purposes only and should NOT be considered medical advice, diagnosis, or treatment.",
                                color: Color.vitalyHeart
                            )
                            .opacity(animateContent ? 1.0 : 0)
                            .offset(y: animateContent ? 0 : 20)

                            // Consult Healthcare Provider
                            DisclaimerCard(
                                icon: "person.fill.questionmark",
                                title: "Consult Your Doctor",
                                description: "Always consult with a qualified healthcare provider before making any decisions about your health, medications, or treatment plans.",
                                color: Color.vitalySleep
                            )
                            .opacity(animateContent ? 1.0 : 0)
                            .offset(y: animateContent ? 0 : 20)

                            // Emergency Notice
                            HStack(spacing: 12) {
                                Image(systemName: "phone.arrow.up.right.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.vitalyHeart)

                                Text("In case of emergency, call emergency services immediately. Do not rely on this app for medical emergencies.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.vitalyTextSecondary)
                            }
                            .padding(16)
                            .background(Color.vitalyHeart.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .opacity(animateContent ? 1.0 : 0)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .clipped()
                .contentShape(Rectangle())

                // Fixed bottom section
                VStack(spacing: 16) {
                    // Acceptance Toggle
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isAccepted.toggle()
                        }
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isAccepted ? Color.vitalyExcellent : Color.vitalyTextSecondary, lineWidth: 2)
                                    .frame(width: 28, height: 28)

                                if isAccepted {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.vitalyExcellent)
                                        .frame(width: 22, height: 22)

                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }

                            Text("I understand that Vitaly provides AI-generated insights for informational purposes only, and I will consult a healthcare professional for medical decisions.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.vitalyTextPrimary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .background(Color.vitalyCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)

                    // Continue Button
                    Button {
                        onContinue()
                    } label: {
                        Text("I Understand & Accept")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                isAccepted ?
                                AnyShapeStyle(LinearGradient.vitalyHeroGradient) :
                                AnyShapeStyle(Color.vitalySurface)
                            )
                            .foregroundStyle(isAccepted ? .white : Color.vitalyTextSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: isAccepted ? Color.vitalyPrimary.opacity(0.4) : Color.clear, radius: 12, x: 0, y: 6)
                    }
                    .disabled(!isAccepted)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 40)
                .background(Color.vitalyBackground)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Disclaimer Card
struct DisclaimerCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.vitalyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Onboarding Animated Wave Layer
struct OnboardingAnimatedWaveLayer: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat
    var offset: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.width
            let height = rect.height
            let midHeight = height * 0.7 - offset

            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: width, y: 0))
            path.addLine(to: CGPoint(x: width, y: midHeight))

            let steps = 100
            for i in stride(from: steps, through: 0, by: -1) {
                let x = (CGFloat(i) / CGFloat(steps)) * width
                let relativeX = x / width
                let sine = sin((relativeX * frequency * 2 * .pi) + phase)
                let y = midHeight + (sine * amplitude)
                path.addLine(to: CGPoint(x: x, y: y))
            }

            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()
        }
    }
}

// MARK: - Onboarding Wave Header
struct OnboardingWaveHeader<Content: View>: View {
    let gradientColors: [Color]
    let content: () -> Content

    @State private var wavePhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

    init(
        gradientColors: [Color] = [Color.vitalyPrimary, Color.vitalySecondary, Color.vitalyTertiary],
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.gradientColors = gradientColors
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .center) {
            // Background waves with gradient
            GeometryReader { geometry in
                ZStack {
                    // Back wave layer
                    OnboardingAnimatedWaveLayer(
                        phase: wavePhase,
                        amplitude: 25,
                        frequency: 1.2,
                        offset: 0
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                gradientColors[safe: 2]?.opacity(0.3) ?? Color.vitalyTertiary.opacity(0.3),
                                gradientColors[safe: 1]?.opacity(0.2) ?? Color.vitalySecondary.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                    // Middle wave layer
                    OnboardingAnimatedWaveLayer(
                        phase: wavePhase + 0.5,
                        amplitude: 20,
                        frequency: 1.5,
                        offset: 10
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                gradientColors[safe: 1]?.opacity(0.4) ?? Color.vitalySecondary.opacity(0.4),
                                gradientColors[safe: 0]?.opacity(0.3) ?? Color.vitalyPrimary.opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Front wave layer
                    OnboardingAnimatedWaveLayer(
                        phase: wavePhase + 1.0,
                        amplitude: 15,
                        frequency: 1.8,
                        offset: 20
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                gradientColors[safe: 0]?.opacity(0.5) ?? Color.vitalyPrimary.opacity(0.5),
                                gradientColors[safe: 1]?.opacity(0.4) ?? Color.vitalySecondary.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
                .blur(radius: 2)
            }
            .frame(height: 260)

            // Pulsing glow effect
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [
                            (gradientColors[safe: 0] ?? Color.vitalyPrimary).opacity(0.3 * pulseScale),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(height: 260)
                .blur(radius: 30)

            // Content
            content()
                .scaleEffect(pulseScale * 0.97 + 0.03)
        }
        .frame(height: 260)
        .background(Color.vitalyBackground)
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            wavePhase = 2 * .pi
        }
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }
    }
}

// Safe array subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
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
                    Text("Welcome to Vitaly")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1.0 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    Text("Your personal health assistant that helps you track and improve your health")
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
                        title: "Track Your Health",
                        description: "Follow important health metrics in real-time"
                    )
                    .opacity(animateContent ? 1.0 : 0)
                    .offset(x: animateContent ? 0 : -30)

                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "AI Insights",
                        description: "Get personalized recommendations"
                    )
                    .opacity(animateContent ? 1.0 : 0)
                    .offset(x: animateContent ? 0 : -30)

                    FeatureRow(
                        icon: "bell.fill",
                        title: "Smart Reminders",
                        description: "Stay on track every day"
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
                    Text("Get Started")
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
    @State private var animateContent = false

    var body: some View {
        ZStack {
            Color.vitalyBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Animated Wave Header
                        OnboardingWaveHeader(
                            gradientColors: [Color.vitalyActivity, Color.vitalyHeart, Color.vitalySecondary]
                        ) {
                            VStack(spacing: 16) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 100, height: 100)

                                    Image(systemName: "heart.text.square.fill")
                                        .font(.system(size: 50, weight: .medium))
                                        .foregroundStyle(.white)
                                }

                                VStack(spacing: 8) {
                                    Text("Connect to Apple Health")
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.vitalyTextPrimary)
                                        .multilineTextAlignment(.center)

                                    Text("We need access to your health data to provide personalized insights and recommendations")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(3)
                                        .padding(.horizontal, 24)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }

                        // Permissions List
                        VStack(spacing: 16) {
                            PermissionRow(
                                icon: "figure.walk",
                                title: "Activity",
                                description: "Steps, distance and workouts",
                                color: Color.vitalyActivity
                            )
                            .opacity(animateContent ? 1.0 : 0)
                            .offset(x: animateContent ? 0 : -20)

                            PermissionRow(
                                icon: "heart.fill",
                                title: "Heart",
                                description: "Heart rate and variability",
                                color: Color.vitalyHeart
                            )
                            .opacity(animateContent ? 1.0 : 0)
                            .offset(x: animateContent ? 0 : -20)

                            PermissionRow(
                                icon: "bed.double.fill",
                                title: "Sleep",
                                description: "Sleep analysis and quality",
                                color: Color.vitalySleep
                            )
                            .opacity(animateContent ? 1.0 : 0)
                            .offset(x: animateContent ? 0 : -20)

                            PermissionRow(
                                icon: "drop.fill",
                                title: "Vital Signs",
                                description: "Blood pressure and oxygen saturation",
                                color: Color.vitalyRecovery
                            )
                            .opacity(animateContent ? 1.0 : 0)
                            .offset(x: animateContent ? 0 : -20)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .clipped()
                .contentShape(Rectangle())

                // Fixed bottom section
                VStack(spacing: 12) {
                    // Privacy Note
                    HStack(spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(Color.vitalyActivity)

                        Text("Your data is encrypted and stays private")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }

                    // Continue Button
                    Button {
                        Task { await onContinue() }
                    } label: {
                        Text(isRequested ? "Continue" : "Enable HealthKit")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(LinearGradient.vitalyActivityGradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.vitalyActivity.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 40)
                .background(Color.vitalyBackground)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Notification Permission Page
struct NotificationPermissionPage: View {
    @Binding var isRequested: Bool
    var onContinue: () async -> Void
    @State private var animateContent = false

    var body: some View {
        ZStack {
            Color.vitalyBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Animated Wave Header
                        OnboardingWaveHeader(
                            gradientColors: [Color.vitalyRecovery, Color.vitalyPrimary, Color.vitalyTertiary]
                        ) {
                            VStack(spacing: 16) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 100, height: 100)

                                    Image(systemName: "bell.badge.fill")
                                        .font(.system(size: 50, weight: .medium))
                                        .foregroundStyle(.white)
                                }

                                VStack(spacing: 8) {
                                    Text("Stay Informed")
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.vitalyTextPrimary)
                                        .multilineTextAlignment(.center)

                                    Text("Get reminders and updates about your health journey")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(3)
                                        .padding(.horizontal, 24)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }

                        // Notification Types
                        VStack(spacing: 16) {
                            NotificationRow(
                                icon: "sparkles",
                                title: "Daily Insights",
                                description: "Personal health tips every day",
                                color: Color.vitalyRecovery
                            )
                            .opacity(animateContent ? 1.0 : 0)
                            .offset(x: animateContent ? 0 : -20)

                            NotificationRow(
                                icon: "target",
                                title: "Goal Reminders",
                                description: "Stay on track with your goals",
                                color: Color.vitalyPrimary
                            )
                            .opacity(animateContent ? 1.0 : 0)
                            .offset(x: animateContent ? 0 : -20)

                            NotificationRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Progress Updates",
                                description: "Celebrate your progress and milestones",
                                color: Color.vitalyActivity
                            )
                            .opacity(animateContent ? 1.0 : 0)
                            .offset(x: animateContent ? 0 : -20)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .clipped()
                .contentShape(Rectangle())

                // Fixed bottom section
                Button {
                    Task { await onContinue() }
                } label: {
                    Text(isRequested ? "Continue" : "Enable Notifications")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(LinearGradient.vitalyRecoveryGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.vitalyRecovery.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 40)
                .background(Color.vitalyBackground)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Profile Setup Page
struct ProfileSetupPage: View {
    @Binding var birthDate: Date
    @Binding var heightCm: Double
    var onContinue: () async -> Void
    @State private var animateContent = false

    var body: some View {
        ZStack {
            Color.vitalyBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Animated Wave Header
                        OnboardingWaveHeader(
                            gradientColors: [Color.vitalyPrimary, Color.vitalySecondary, Color.vitalyTertiary]
                        ) {
                            VStack(spacing: 16) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 100, height: 100)

                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 50, weight: .medium))
                                        .foregroundStyle(.white)
                                }

                                VStack(spacing: 8) {
                                    Text("About You")
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.vitalyTextPrimary)
                                        .multilineTextAlignment(.center)

                                    Text("We need some information to calculate your health metrics accurately")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(3)
                                        .padding(.horizontal, 24)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }

                        // Form Fields
                        VStack(spacing: 24) {
                            // Birth Date Card
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.vitalyPrimary.opacity(0.15))
                                            .frame(width: 48, height: 48)

                                        Image(systemName: "birthday.cake.fill")
                                            .font(.system(size: 22, weight: .medium))
                                            .foregroundStyle(Color.vitalyPrimary)
                                    }

                                    Text("Birth Date")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(Color.vitalyTextPrimary)

                                    Spacer()
                                }

                                DatePicker(
                                    "",
                                    selection: $birthDate,
                                    in: ...Date(),
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(height: 120)
                                .clipped()
                            }
                            .padding(20)
                            .background(Color.vitalyCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .opacity(animateContent ? 1.0 : 0)
                            .offset(y: animateContent ? 0 : 20)

                            // Height Card
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.vitalySleep.opacity(0.15))
                                            .frame(width: 48, height: 48)

                                        Image(systemName: "ruler.fill")
                                            .font(.system(size: 22, weight: .medium))
                                            .foregroundStyle(Color.vitalySleep)
                                    }

                                    Text("Height")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(Color.vitalyTextPrimary)

                                    Spacer()

                                    Text("\(Int(heightCm)) cm")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.vitalyTextPrimary)
                                }

                                Slider(value: $heightCm, in: 100...250, step: 1)
                                    .tint(Color.vitalySleep)

                                HStack {
                                    Text("100 cm")
                                        .font(.caption)
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                    Spacer()
                                    Text("250 cm")
                                        .font(.caption)
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                }
                            }
                            .padding(20)
                            .background(Color.vitalyCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .opacity(animateContent ? 1.0 : 0)
                            .offset(y: animateContent ? 0 : 20)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .clipped()
                .contentShape(Rectangle())

                // Fixed bottom section
                Button {
                    Task { await onContinue() }
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(LinearGradient.vitalyHeroGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.vitalyPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 40)
                .background(Color.vitalyBackground)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Completion Page
struct CompletionPage: View {
    var onFinish: () -> Void
    @State private var animateContent = false
    @State private var showCheckmarks = [false, false, false, false]

    var body: some View {
        ZStack {
            Color.vitalyBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Animated Wave Header with success color
                        OnboardingWaveHeader(
                            gradientColors: [Color.vitalyExcellent, Color(hex: "#4CAF50"), Color(hex: "#8BC34A")]
                        ) {
                            VStack(spacing: 16) {
                                // Checkmark Icon
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 110, height: 110)

                                    Image(systemName: "checkmark")
                                        .font(.system(size: 55, weight: .bold))
                                        .foregroundStyle(.white)
                                }

                                VStack(spacing: 8) {
                                    Text("All Done!")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.vitalyTextPrimary)
                                        .multilineTextAlignment(.center)

                                    Text("You're now ready to start your health journey with us")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(3)
                                        .padding(.horizontal, 24)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }

                        // Success Items
                        VStack(spacing: 16) {
                            CompletionRow(
                                icon: "checkmark.circle.fill",
                                title: "Account Created",
                                color: Color.vitalyExcellent,
                                isVisible: showCheckmarks[0]
                            )

                            CompletionRow(
                                icon: "checkmark.circle.fill",
                                title: "HealthKit Connected",
                                color: Color.vitalyExcellent,
                                isVisible: showCheckmarks[1]
                            )

                            CompletionRow(
                                icon: "checkmark.circle.fill",
                                title: "Notifications Enabled",
                                color: Color.vitalyExcellent,
                                isVisible: showCheckmarks[2]
                            )

                            CompletionRow(
                                icon: "checkmark.circle.fill",
                                title: "Profile Configured",
                                color: Color.vitalyExcellent,
                                isVisible: showCheckmarks[3]
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 24)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .clipped()
                .contentShape(Rectangle())

                // Fixed bottom section
                Button {
                    onFinish()
                } label: {
                    Text("Start Using the App")
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
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 40)
                .background(Color.vitalyBackground)
            }
        }
        .onAppear {
            // Staggered animation for checkmarks
            for i in 0..<4 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.15 + 0.3)) {
                    showCheckmarks[i] = true
                }
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.9)) {
                animateContent = true
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
    var color: Color = Color.vitalyActivity

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.vitalyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct NotificationRow: View {
    let icon: String
    let title: String
    let description: String
    var color: Color = Color.vitalyRecovery

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.vitalyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct CompletionRow: View {
    let icon: String
    let title: String
    let color: Color
    var isVisible: Bool = true

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(color)
                .scaleEffect(isVisible ? 1.0 : 0.3)
                .opacity(isVisible ? 1.0 : 0)

            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.vitalyTextPrimary)

            Spacer()
        }
        .padding(16)
        .background(Color.vitalyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isVisible ? 1.0 : 0)
        .offset(x: isVisible ? 0 : -20)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppCoordinator())
}
