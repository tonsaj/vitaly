import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Bindable var viewModel: AuthViewModel
    @FocusState private var focusedField: Field?
    @State private var wavePhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

    enum Field: Hashable {
        case phoneNumber, verificationCode
    }

    var body: some View {
        ZStack {
            // Dark Background
            Color.vitalyBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Wave Header with Gradient
                    waveHeaderSection

                    // Main Content
                    VStack(spacing: 24) {
                        // Form based on auth step
                        if viewModel.authStep == .phoneInput {
                            phoneInputSection
                        } else {
                            verificationCodeSection
                        }

                        // Divider
                        dividerSection

                        // Apple Sign In
                        appleSignInButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 40)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .clipped()
            .contentShape(Rectangle())
        }
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Wave Header Section (Same style as Dashboard)
    private var waveHeaderSection: some View {
        ZStack(alignment: .center) {
            // Background waves with gradient (same as WavyHeaderView)
            GeometryReader { geometry in
                ZStack {
                    // Back wave layer
                    LoginAnimatedWaveLayer(
                        phase: wavePhase,
                        amplitude: 25,
                        frequency: 1.2,
                        offset: 0
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.vitalyTertiary.opacity(0.3),
                                Color.vitalySecondary.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                    // Middle wave layer
                    LoginAnimatedWaveLayer(
                        phase: wavePhase + 0.5,
                        amplitude: 20,
                        frequency: 1.5,
                        offset: 10
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.vitalySecondary.opacity(0.4),
                                Color.vitalyPrimary.opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Front wave layer
                    LoginAnimatedWaveLayer(
                        phase: wavePhase + 1.0,
                        amplitude: 15,
                        frequency: 1.8,
                        offset: 20
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.vitalyPrimary.opacity(0.5),
                                Color.vitalySecondary.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
                .blur(radius: 2)
            }
            .frame(height: 280)

            // Pulsing glow effect
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.vitalyPrimary.opacity(0.3 * pulseScale),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(height: 280)
                .blur(radius: 30)

            // Content
            VStack(spacing: 16) {
                // Animated Sunburst Icon
                AnimatedSunburstLogo()
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseScale * 0.95)

                VStack(spacing: 6) {
                    Text(viewModel.authStep == .phoneInput ? "Welcome" : "Verify")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.vitalyTextPrimary, Color.vitalyTextPrimary.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(viewModel.authStep == .phoneInput ? "Sign in with your phone number" : "Enter verification code")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }
        .frame(height: 280)
        .background(Color.vitalyBackground)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.authStep)
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            wavePhase = 2 * .pi
        }
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
    }

    // MARK: - Phone Input Section
    private var phoneInputSection: some View {
        VStack(spacing: 20) {
            // Phone Number Field
            VStack(alignment: .leading, spacing: 12) {
                Text("Phone Number")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.vitalyTextSecondary)

                HStack(spacing: 14) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.vitalyPrimary)
                        .frame(width: 24)

                    TextField("07X XXX XX XX", text: $viewModel.phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .focused($focusedField, equals: .phoneNumber)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .tint(Color.vitalyPrimary)
                        .onChange(of: viewModel.phoneNumber) { oldValue, newValue in
                            // Auto-format phone number as user types
                            viewModel.phoneNumber = formatPhoneNumberInput(newValue)
                        }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(Color.vitalyCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            focusedField == .phoneNumber ? Color.vitalyPrimary : Color.vitalySurface,
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: focusedField == .phoneNumber ? Color.vitalyPrimary.opacity(0.15) : .clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }

            // Login Button
            Button {
                focusedField = nil
                Task { await viewModel.sendVerificationCode() }
            } label: {
                HStack(spacing: 12) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.1)
                    } else {
                        Text("Sign In")
                            .font(.system(size: 17, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    viewModel.isPhoneNumberValid ?
                        LinearGradient.vitalyHeroGradient :
                        LinearGradient(
                            colors: [Color.vitalySurface, Color.vitalySurface],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(
                    color: viewModel.isPhoneNumberValid ? Color.vitalyPrimary.opacity(0.5) : Color.clear,
                    radius: 16,
                    x: 0,
                    y: 8
                )
            }
            .disabled(!viewModel.isPhoneNumberValid || viewModel.isLoading)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isPhoneNumberValid)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }

    // MARK: - Verification Code Section
    private var verificationCodeSection: some View {
        VStack(spacing: 20) {
            // Phone number display
            HStack(spacing: 8) {
                Text("Code sent to")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.vitalyTextSecondary)

                Text(viewModel.phoneNumber)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.vitalyPrimary)

                Button {
                    viewModel.backToPhoneInput()
                } label: {
                    Text("Change")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.vitalySecondary)
                }
            }
            .padding(.bottom, 10)

            // Verification Code Field
            VStack(alignment: .leading, spacing: 12) {
                Text("Verification Code")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.vitalyTextSecondary)

                HStack(spacing: 14) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.vitalyPrimary)
                        .frame(width: 24)

                    TextField("000000", text: $viewModel.verificationCode)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .verificationCode)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .tint(Color.vitalyPrimary)
                        .onChange(of: viewModel.verificationCode) { oldValue, newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                viewModel.verificationCode = String(newValue.prefix(6))
                            }
                        }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(Color.vitalyCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            focusedField == .verificationCode ? Color.vitalyPrimary : Color.vitalySurface,
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: focusedField == .verificationCode ? Color.vitalyPrimary.opacity(0.15) : .clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }

            // Resend code button
            HStack {
                Spacer()
                Button {
                    Task { await viewModel.resendCode() }
                } label: {
                    Text("Resend Code")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.vitalySecondary)
                }
                .disabled(viewModel.isLoading)
            }

            // Verify Button
            Button {
                focusedField = nil
                Task { await viewModel.verifyCode() }
            } label: {
                HStack(spacing: 12) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.1)
                    } else {
                        Text("Verify")
                            .font(.system(size: 17, weight: .bold))
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    viewModel.isVerificationCodeValid ?
                        LinearGradient.vitalyHeroGradient :
                        LinearGradient(
                            colors: [Color.vitalySurface, Color.vitalySurface],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(
                    color: viewModel.isVerificationCodeValid ? Color.vitalyPrimary.opacity(0.5) : Color.clear,
                    radius: 16,
                    x: 0,
                    y: 8
                )
            }
            .disabled(!viewModel.isVerificationCodeValid || viewModel.isLoading)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isVerificationCodeValid)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .onAppear {
            focusedField = .verificationCode
        }
    }

    // MARK: - Divider Section
    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.vitalySurface.opacity(0.6))
                .frame(height: 1)

            Text("or")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.vitalyTextSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Rectangle()
                .fill(Color.vitalySurface.opacity(0.6))
                .frame(height: 1)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Google Sign In Button
    private var googleSignInButton: some View {
        Button {
            viewModel.signInWithGoogle()
        } label: {
            HStack(spacing: 16) {
                // Google "G" logo with larger size
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 32, height: 32)

                    Text("G")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .yellow, .green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Google")
                    .font(.system(size: 19, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(Color.white)
            .foregroundStyle(.black.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        }
        .disabled(viewModel.isLoading)
    }

    // MARK: - Apple Sign In Button
    private var appleSignInButton: some View {
        Button {
            viewModel.triggerAppleSignIn()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 20, weight: .medium))

                Text("Apple")
                    .font(.system(size: 19, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(Color.white)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        }
        .disabled(viewModel.isLoading)
    }

    // MARK: - Helper Methods
    private func formatPhoneNumberInput(_ input: String) -> String {
        // Remove all non-digit characters except +
        let cleaned = input.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)

        // Limit length
        if cleaned.hasPrefix("+46") {
            return String(cleaned.prefix(12)) // +46XXXXXXXXX
        } else if cleaned.hasPrefix("0") {
            return String(cleaned.prefix(10)) // 07XXXXXXXX
        }
        return String(cleaned.prefix(10))
    }
}

// MARK: - Login Animated Wave Layer (Same as Dashboard)
struct LoginAnimatedWaveLayer: Shape {
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

#Preview("Login View - Phone Input") {
    LoginView(
        viewModel: AuthViewModel(
            authService: AuthService(),
            coordinator: AppCoordinator()
        )
    )
}

#Preview("Login View - Code Verification") {
    let viewModel = AuthViewModel(
        authService: AuthService(),
        coordinator: AppCoordinator()
    )
    viewModel.authStep = .codeVerification
    viewModel.phoneNumber = "070 123 45 67"

    return LoginView(viewModel: viewModel)
}
