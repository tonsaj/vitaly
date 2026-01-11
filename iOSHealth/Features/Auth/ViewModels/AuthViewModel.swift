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
        guard isPhoneNumberValid else {
            showErrorMessage("Ange ett giltigt svenskt telefonnummer")
            return
        }

        isLoading = true
        errorMessage = nil
        showError = false

        do {
            let formattedNumber = formatPhoneNumber(phoneNumber)
            verificationID = try await authService.sendVerificationCode(phoneNumber: formattedNumber)
            authStep = .codeVerification
        } catch {
            handleAuthError(error)
        }

        isLoading = false
    }

    func verifyCode() async {
        guard let verificationID = verificationID, isVerificationCodeValid else {
            showErrorMessage("Ange en giltig verifieringskod")
            return
        }

        isLoading = true
        errorMessage = nil
        showError = false

        do {
            try await authService.verifyCode(verificationID: verificationID, code: verificationCode)
        } catch {
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

        // Match Swedish phone numbers: +46XXXXXXXXX or 07XXXXXXXX
        let phoneRegex = "^(\\+46|0)[1-9]\\d{8,9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: cleaned)
    }

    private func formatPhoneNumber(_ phone: String) -> String {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        // Convert 07XXXXXXXX to +46 7XXXXXXXX
        if cleaned.hasPrefix("0") {
            return "+46" + cleaned.dropFirst()
        }
        return cleaned
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
