import SwiftUI
import AuthenticationServices
import Combine

@MainActor
@Observable
final class AuthViewModel {
    // MARK: - Published Properties
    var phoneNumber = ""
    var verificationCode = ""
    var verificationID: String?
    var authStep: AuthStep = .phoneInput

    var isLoading = false
    var errorMessage: String?
    var showError = false

    // MARK: - Dependencies
    private let authService: AuthService
    var coordinator: AppCoordinator

    // MARK: - Computed Properties
    var isPhoneNumberValid: Bool {
        isValidSwedishPhoneNumber(phoneNumber)
    }

    var isVerificationCodeValid: Bool {
        verificationCode.count == 6 && verificationCode.allSatisfy { $0.isNumber }
    }

    // MARK: - Initialization
    init(authService: AuthService, coordinator: AppCoordinator) {
        self.authService = authService
        self.coordinator = coordinator
    }

    // MARK: - Phone Authentication Methods
    func sendVerificationCode() async {
        print("📱 AuthViewModel: sendVerificationCode called")

        guard isPhoneNumberValid else {
            print("❌ AuthViewModel: Phone number validation failed")
            showErrorMessage("Ange ett giltigt svenskt telefonnummer")
            return
        }

        print("✅ AuthViewModel: Phone number validation passed")

        isLoading = true
        errorMessage = nil
        showError = false

        do {
            let formattedNumber = formatPhoneNumber(phoneNumber)
            print("📱 AuthViewModel: Calling authService.sendVerificationCode with: \(formattedNumber)")

            verificationID = try await authService.sendVerificationCode(phoneNumber: formattedNumber)

            print("✅ AuthViewModel: Received verification ID: \(verificationID ?? "nil")")
            authStep = .codeVerification
        } catch {
            print("❌ AuthViewModel: Send verification code failed: \(error)")
            handleAuthError(error)
        }

        isLoading = false
    }

    func verifyCode() async {
        print("📱 AuthViewModel: verifyCode called")

        guard let verificationID = verificationID, isVerificationCodeValid else {
            print("❌ AuthViewModel: Verification code validation failed")
            print("❌ AuthViewModel: verificationID: \(verificationID ?? "nil")")
            print("❌ AuthViewModel: code: \(verificationCode)")
            print("❌ AuthViewModel: isVerificationCodeValid: \(isVerificationCodeValid)")
            showErrorMessage("Ange en giltig verifieringskod")
            return
        }

        print("✅ AuthViewModel: Verification code validation passed")

        isLoading = true
        errorMessage = nil
        showError = false

        do {
            print("📱 AuthViewModel: Calling authService.verifyCode")
            try await authService.verifyCode(verificationID: verificationID, code: verificationCode)
            print("✅ AuthViewModel: Verification successful")
        } catch {
            print("❌ AuthViewModel: Verification failed: \(error)")
            handleAuthError(error)
        }

        isLoading = false
    }

    func resendCode() async {
        await sendVerificationCode()
    }

    func backToPhoneInput() {
        authStep = .phoneInput
        verificationCode = ""
        verificationID = nil
    }

    func signInWithGoogle() {
        Task {
            isLoading = true
            errorMessage = nil
            showError = false

            do {
                try await authService.signInWithGoogle()
            } catch {
                handleAuthError(error)
            }

            isLoading = false
        }
    }

    func triggerAppleSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = AppleSignInDelegate.shared
        AppleSignInDelegate.shared.viewModel = self
        controller.performRequests()
    }

    func signInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                showErrorMessage("Kunde inte verifiera Apple ID")
                return
            }

            Task {
                isLoading = true
                errorMessage = nil
                showError = false

                do {
                    try await authService.signInWithApple(credential: credential)
                } catch {
                    handleAuthError(error)
                }

                isLoading = false
            }

        case .failure(let error):
            let nsError = error as NSError
            if nsError.code != ASAuthorizationError.canceled.rawValue {
                handleAuthError(error)
            }
        }
    }

    // MARK: - Validation Methods
    private func isValidSwedishPhoneNumber(_ phone: String) -> Bool {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        print("📱 Phone Validation: Original: \(phone)")
        print("📱 Phone Validation: Cleaned: \(cleaned)")

        // More flexible regex for Swedish phone numbers
        // Supports: +46XXXXXXXXX (9-10 digits), 07XXXXXXXX (10 digits), 46XXXXXXXXX
        let phoneRegex = "^(\\+46|0046|0)[1-9]\\d{8,9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        let isValid = phonePredicate.evaluate(with: cleaned)

        print("📱 Phone Validation: Is valid: \(isValid)")
        return isValid
    }

    private func formatPhoneNumber(_ phone: String) -> String {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        print("📱 Phone Format: Input: \(phone)")
        print("📱 Phone Format: Cleaned: \(cleaned)")

        var formatted: String

        // Convert various formats to +46 7XXXXXXXX
        if cleaned.hasPrefix("0046") {
            // 0046 7XXXXXXXX -> +46 7XXXXXXXX
            formatted = "+46" + cleaned.dropFirst(4)
        } else if cleaned.hasPrefix("46") && !cleaned.hasPrefix("+46") {
            // 46 7XXXXXXXX -> +46 7XXXXXXXX
            formatted = "+46" + cleaned.dropFirst(2)
        } else if cleaned.hasPrefix("0") {
            // 07XXXXXXXX -> +46 7XXXXXXXX
            formatted = "+46" + cleaned.dropFirst()
        } else if cleaned.hasPrefix("+46") {
            // Already correctly formatted
            formatted = cleaned
        } else {
            // Assume it's missing country code
            formatted = "+46" + cleaned
        }

        print("📱 Phone Format: Output: \(formatted)")
        return formatted
    }

    // MARK: - Error Handling
    private func handleAuthError(_ error: Error) {
        if let authError = error as? AuthError {
            showErrorMessage(authError.errorDescription ?? "Ett okänt fel uppstod")
        } else {
            showErrorMessage("Ett fel uppstod. Försök igen.")
        }
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }

    // MARK: - Reset Methods
    func resetForm() {
        phoneNumber = ""
        verificationCode = ""
        verificationID = nil
        authStep = .phoneInput
        errorMessage = nil
        showError = false
    }
}

// MARK: - Supporting Types
enum AuthStep {
    case phoneInput
    case codeVerification
}

// MARK: - Apple Sign In Delegate
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    static let shared = AppleSignInDelegate()
    weak var viewModel: AuthViewModel?

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        viewModel?.signInWithApple(result: .success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        viewModel?.signInWithApple(result: .failure(error))
    }
}
