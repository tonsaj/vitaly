import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Bindable var viewModel: AuthViewModel
    @FocusState private var focusedField: Field?

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
                    VStack(spacing: 32) {
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
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Fel", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Wave Header Section
    private var waveHeaderSection: some View {
        ZStack(alignment: .bottom) {
            // Gradient Background with Waves
            LinearGradient.vitalyHeroGradient
                .frame(height: 320)
                .overlay(
                    GeometryReader { geometry in
                        WaveShape(phase: 0)
                            .fill(
                                Color.vitalySecondary.opacity(0.3)
                            )
                            .frame(height: 320)

                        WaveShape(phase: .pi)
                            .fill(
                                Color.vitalyTertiary.opacity(0.2)
                            )
                            .frame(height: 320)
                    }
                )
                .clipShape(
                    .rect(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 40,
                        bottomTrailingRadius: 40,
                        topTrailingRadius: 0
                    )
                )

            // Content
            VStack(spacing: 20) {
                // Animated Sunburst Icon
                AnimatedSunburstLogo()
                    .frame(width: 120, height: 120)

                VStack(spacing: 8) {
                    Text(viewModel.authStep == .phoneInput ? "Välkommen" : "Verifiera")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(viewModel.authStep == .phoneInput ? "Logga in med ditt telefonnummer" : "Ange verifieringskoden")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(.bottom, 50)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.authStep)
    }

    // MARK: - Phone Input Section
    private var phoneInputSection: some View {
        VStack(spacing: 20) {
            // Phone Number Field
            VStack(alignment: .leading, spacing: 10) {
                Text("Telefonnummer")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.vitalyTextSecondary)

                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .foregroundStyle(Color.vitalyPrimary)
                        .frame(width: 20)

                    TextField("07X XXX XX XX", text: $viewModel.phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .focused($focusedField, equals: .phoneNumber)
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .tint(Color.vitalyPrimary)
                        .onChange(of: viewModel.phoneNumber) { oldValue, newValue in
                            // Auto-format phone number as user types
                            viewModel.phoneNumber = formatPhoneNumberInput(newValue)
                        }
                }
                .padding(16)
                .background(Color.vitalyCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            focusedField == .phoneNumber ? Color.vitalyPrimary : Color.vitalySurface,
                            lineWidth: 1.5
                        )
                )
            }

            Text("Vi skickar en SMS med en verifieringskod")
                .font(.system(size: 14))
                .foregroundStyle(Color.vitalyTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Send Code Button
            Button {
                focusedField = nil
                Task { await viewModel.sendVerificationCode() }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Skicka kod")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
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
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: viewModel.isPhoneNumberValid ? Color.vitalyPrimary.opacity(0.4) : Color.clear,
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            .disabled(!viewModel.isPhoneNumberValid || viewModel.isLoading)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isPhoneNumberValid)
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
                Text("Kod skickad till")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.vitalyTextSecondary)

                Text(viewModel.phoneNumber)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.vitalyPrimary)

                Button {
                    viewModel.backToPhoneInput()
                } label: {
                    Text("Ändra")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.vitalySecondary)
                }
            }
            .padding(.bottom, 10)

            // Verification Code Field
            VStack(alignment: .leading, spacing: 10) {
                Text("Verifieringskod")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.vitalyTextSecondary)

                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Color.vitalyPrimary)
                        .frame(width: 20)

                    TextField("000000", text: $viewModel.verificationCode)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .verificationCode)
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .tint(Color.vitalyPrimary)
                        .onChange(of: viewModel.verificationCode) { oldValue, newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                viewModel.verificationCode = String(newValue.prefix(6))
                            }
                        }
                }
                .padding(16)
                .background(Color.vitalyCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            focusedField == .verificationCode ? Color.vitalyPrimary : Color.vitalySurface,
                            lineWidth: 1.5
                        )
                )
            }

            // Resend code button
            HStack {
                Spacer()
                Button {
                    Task { await viewModel.resendCode() }
                } label: {
                    Text("Skicka kod igen")
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
                HStack(spacing: 10) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Verifiera")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
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
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: viewModel.isVerificationCodeValid ? Color.vitalyPrimary.opacity(0.4) : Color.clear,
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            .disabled(!viewModel.isVerificationCodeValid || viewModel.isLoading)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isVerificationCodeValid)
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
                .fill(Color.vitalySurface)
                .frame(height: 1)

            Text("eller")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.vitalyTextSecondary)

            Rectangle()
                .fill(Color.vitalySurface)
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Apple Sign In Button
    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            viewModel.signInWithApple(result: result)
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

// MARK: - Animated Sunburst Logo
struct AnimatedSunburstLogo: View {
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Animated outer rays
            ForEach(0..<12, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 3, height: 20)
                    .offset(y: -50)
                    .rotationEffect(.degrees(Double(index) * 30 + rotationAngle))
            }

            // Secondary inner rays
            ForEach(0..<12, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 2, height: 12)
                    .offset(y: -38)
                    .rotationEffect(.degrees(Double(index) * 30 + 15 - rotationAngle * 0.5))
            }

            // Pulsing glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.4), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 45
                    )
                )
                .frame(width: 90, height: 90)
                .scaleEffect(pulseScale)

            // Inner circle
            Circle()
                .fill(.white)
                .frame(width: 68, height: 68)
                .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)

            // Sun symbol with gradient
            Image(systemName: "sun.max.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.vitalyPrimary, Color.vitalySecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, options: .repeat(2).speed(0.5))
        }
        .onAppear {
            // Continuous rotation animation
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }

            // Pulsing animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.2
            }
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
