import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift
import UIKit

// MARK: - Phone Auth UI Delegate
@MainActor
class PhoneAuthUIDelegate: NSObject, AuthUIDelegate {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion?()
            return
        }

        // Find the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }

        topController.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            completion?()
            return
        }

        // Find the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }

        topController.dismiss(animated: flag, completion: completion)
    }
}

@MainActor
final class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: AuthError?
    @Published var isAuthResolved = false

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let phoneAuthUIDelegate = PhoneAuthUIDelegate()

    init() {
        setupAuthStateListener()
    }

    deinit {
        if let listener = authStateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }

    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    await self?.fetchUserProfile(userId: firebaseUser.uid)
                } else {
                    self?.currentUser = nil
                }
                self?.isAuthResolved = true
            }
        }
    }

    // MARK: - Phone Authentication
    func sendVerificationCode(phoneNumber: String) async throws -> String {
        print("📱 Phone Auth: Starting verification code send")
        print("📱 Phone Auth: Phone number: \(phoneNumber)")

        isLoading = true
        defer { isLoading = false }

        do {
            print("📱 Phone Auth: Calling PhoneAuthProvider.verifyPhoneNumber")
            print("📱 Phone Auth: Using UI delegate for reCAPTCHA fallback")
            let verificationID = try await PhoneAuthProvider.provider()
                .verifyPhoneNumber(phoneNumber, uiDelegate: phoneAuthUIDelegate)

            print("✅ Phone Auth: Successfully sent verification code")
            print("📱 Phone Auth: Verification ID: \(verificationID)")

            return verificationID
        } catch let error as NSError {
            print("❌ Phone Auth: Send verification failed")
            print("❌ Phone Auth: Error code: \(error.code)")
            print("❌ Phone Auth: Error domain: \(error.domain)")
            print("❌ Phone Auth: Error description: \(error.localizedDescription)")
            print("❌ Phone Auth: Error userInfo: \(error.userInfo)")

            // Provide more helpful error messages
            if error.domain == "FIRAuthErrorDomain" {
                switch error.code {
                case 17010: // FIRAuthErrorCodeInvalidPhoneNumber
                    print("❌ Phone Auth: Invalid phone number format")
                case 17065: // FIRAuthErrorCodeQuotaExceeded
                    print("❌ Phone Auth: SMS quota exceeded. Try again later.")
                case 17999: // FIRAuthErrorCodeMissingAppCredential
                    print("❌ Phone Auth: Missing APNS token. Device not registered for remote notifications.")
                case 17028: // FIRAuthErrorCodeInvalidAppCredential
                    print("❌ Phone Auth: Invalid APNS token configuration")
                default:
                    print("❌ Phone Auth: Unhandled error code: \(error.code)")
                }
            }

            self.error = AuthError.from(error)
            throw error
        }
    }

    func verifyCode(verificationID: String, code: String) async throws {
        print("📱 Phone Auth: Starting verification code validation")
        print("📱 Phone Auth: Verification ID: \(verificationID)")
        print("📱 Phone Auth: Code: \(code)")

        isLoading = true
        defer { isLoading = false }

        do {
            print("📱 Phone Auth: Creating credential")
            let credential = PhoneAuthProvider.provider()
                .credential(withVerificationID: verificationID, verificationCode: code)

            print("📱 Phone Auth: Attempting sign in with credential")
            let result = try await auth.signIn(with: credential)
            print("✅ Phone Auth: Successfully signed in")
            print("📱 Phone Auth: User ID: \(result.user.uid)")
            print("📱 Phone Auth: Phone number: \(result.user.phoneNumber ?? "nil")")

            // Check if user exists, otherwise create new profile
            print("📱 Phone Auth: Checking if user profile exists in Firestore")
            let userDoc = try await db.collection("users").document(result.user.uid).getDocument()

            if !userDoc.exists {
                print("📱 Phone Auth: User profile doesn't exist, creating new profile")
                let user = User(
                    id: result.user.uid,
                    phoneNumber: result.user.phoneNumber ?? "",
                    displayName: nil,
                    createdAt: Date()
                )
                try await saveUserProfile(user)
                currentUser = user
                print("✅ Phone Auth: Created new user profile")
            } else {
                print("📱 Phone Auth: User profile exists, fetching from Firestore")
                await fetchUserProfile(userId: result.user.uid)
                print("✅ Phone Auth: Fetched existing user profile")
            }
        } catch let error as NSError {
            print("❌ Phone Auth: Verification failed")
            print("❌ Phone Auth: Error code: \(error.code)")
            print("❌ Phone Auth: Error domain: \(error.domain)")
            print("❌ Phone Auth: Error description: \(error.localizedDescription)")
            print("❌ Phone Auth: Error userInfo: \(error.userInfo)")

            // Provide more helpful error messages
            if error.domain == "FIRAuthErrorDomain" {
                switch error.code {
                case 17044: // FIRAuthErrorCodeInvalidVerificationCode
                    print("❌ Phone Auth: Invalid verification code")
                case 17051: // FIRAuthErrorCodeSessionExpired
                    print("❌ Phone Auth: Verification code expired")
                case 17046: // FIRAuthErrorCodeMissingVerificationCode
                    print("❌ Phone Auth: Missing verification code")
                default:
                    print("❌ Phone Auth: Unhandled error code: \(error.code)")
                }
            }

            self.error = AuthError.from(error)
            throw error
        }
    }

    // MARK: - Google Authentication
    func signInWithGoogle() async throws {
        isLoading = true
        defer { isLoading = false }

        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            throw AuthError.unknown("Kunde inte hitta root view controller")
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.invalidCredential
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await auth.signIn(with: credential)

            // Check if user exists
            let userDoc = try await db.collection("users").document(authResult.user.uid).getDocument()

            if !userDoc.exists {
                let user = User(
                    id: authResult.user.uid,
                    phoneNumber: "",
                    email: result.user.profile?.email,
                    displayName: result.user.profile?.name,
                    createdAt: Date()
                )
                try await saveUserProfile(user)
                currentUser = user
            } else {
                await fetchUserProfile(userId: authResult.user.uid)
            }
        } catch {
            self.error = AuthError.from(error)
            throw error
        }
    }

    // MARK: - Apple Authentication
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        isLoading = true
        defer { isLoading = false }

        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidCredential
        }

        // Build display name from Apple credential (only available on first sign-in)
        let appleDisplayName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        print("🍎 Apple Sign-In - Apple provided name: '\(appleDisplayName)'")

        let oAuthCredential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: nil,
            fullName: credential.fullName
        )

        do {
            let result = try await auth.signIn(with: oAuthCredential)

            // Force refresh user data from Firebase
            try? await result.user.reload()
            print("🍎 Firebase Auth - Current displayName: '\(result.user.displayName ?? "nil")'")

            // Check provider data for Apple displayName
            var providerDisplayName: String?
            var providerEmail: String?
            for provider in result.user.providerData {
                print("🍎 Provider: \(provider.providerID), displayName: '\(provider.displayName ?? "nil")', email: '\(provider.email ?? "nil")'")
                if provider.providerID == "apple.com" {
                    if let name = provider.displayName, !name.isEmpty {
                        providerDisplayName = name
                    }
                    if let email = provider.email, !email.isEmpty {
                        providerEmail = email
                    }
                }
            }

            // If we got a name from Apple credential, update Firebase Auth profile
            if !appleDisplayName.isEmpty {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = appleDisplayName
                try await changeRequest.commitChanges()
                print("🍎 Updated Firebase Auth displayName to: '\(appleDisplayName)'")
            }

            // Get the best available display name (priority: Apple credential > provider data > Firebase Auth)
            let finalDisplayName: String?
            if !appleDisplayName.isEmpty {
                finalDisplayName = appleDisplayName
            } else if let providerName = providerDisplayName {
                finalDisplayName = providerName
                print("🍎 Using provider displayName: '\(providerName)'")
            } else if let firebaseDisplayName = result.user.displayName, !firebaseDisplayName.isEmpty {
                finalDisplayName = firebaseDisplayName
            } else {
                finalDisplayName = nil
            }

            // Get email from provider if not from credential
            let finalEmail = credential.email ?? providerEmail ?? result.user.email

            print("🍎 Final display name to use: '\(finalDisplayName ?? "nil")'")

            // Check if user exists in Firestore
            let userDoc = try await db.collection("users").document(result.user.uid).getDocument()

            if !userDoc.exists {
                // New user - create profile
                let user = User(
                    id: result.user.uid,
                    phoneNumber: result.user.phoneNumber ?? "",
                    email: finalEmail,
                    displayName: finalDisplayName,
                    createdAt: Date()
                )
                print("🍎 Creating new user with displayName: '\(user.displayName ?? "nil")'")
                try await saveUserProfile(user)
                currentUser = user
            } else {
                // Existing user - fetch and update if needed
                print("🍎 User exists in Firestore, fetching profile...")
                await fetchUserProfile(userId: result.user.uid)
                print("🍎 Fetched user displayName: '\(currentUser?.displayName ?? "nil")'")

                // Update display name if we have a new one and user doesn't have one
                if (currentUser?.displayName == nil || currentUser?.displayName?.isEmpty == true),
                   let name = finalDisplayName {
                    print("🍎 Updating displayName from '\(currentUser?.displayName ?? "nil")' to '\(name)'")
                    currentUser?.displayName = name
                    if var user = currentUser {
                        user.displayName = name
                        try await saveUserProfile(user)
                        print("🍎 Successfully saved updated displayName to Firestore")
                    }
                }
            }
        } catch {
            print("🍎 Error during Apple Sign-In: \(error)")
            self.error = AuthError.from(error)
            throw error
        }
    }

    func signOut() {
        do {
            try auth.signOut()
            currentUser = nil
        } catch {
            self.error = AuthError.from(error)
        }
    }

    private func fetchUserProfile(userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            print("👤 Hämtar användarprofil: \(userId)")

            var user = try document.data(as: User.self)

            // Logga all användardata
            print("👤 ── Användarprofil ──")
            print("👤 Namn: \(user.displayName ?? "saknas")")
            print("👤 Email: \(user.email ?? "saknas")")
            print("👤 Telefon: \(user.phoneNumber ?? "saknas")")
            if let birthDate = user.birthDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                print("👤 Födelsedatum: \(formatter.string(from: birthDate)) (ålder: \(user.age ?? 0))")
            } else {
                print("👤 Födelsedatum: saknas")
            }
            print("👤 Längd: \(user.heightCm != nil ? "\(Int(user.heightCm!)) cm" : "saknas")")
            print("👤 ─────────────────────")

            // If displayName is missing, try to get it from Firebase Auth
            if (user.displayName == nil || user.displayName?.isEmpty == true),
               let firebaseDisplayName = auth.currentUser?.displayName,
               !firebaseDisplayName.isEmpty {
                print("👤 Hämtar namn från Firebase Auth: '\(firebaseDisplayName)'")
                user.displayName = firebaseDisplayName
                try await saveUserProfile(user)
            }

            currentUser = user
        } catch {
            print("📱 Error fetching user profile: \(error)")
            // Create basic profile if doesn't exist
            if let firebaseUser = auth.currentUser {
                print("📱 Creating fallback user profile with Firebase Auth displayName: '\(firebaseUser.displayName ?? "nil")'")
                let user = User(
                    id: firebaseUser.uid,
                    phoneNumber: firebaseUser.phoneNumber ?? "",
                    email: firebaseUser.email,
                    displayName: firebaseUser.displayName,
                    createdAt: Date()
                )
                currentUser = user
                // Save to Firestore
                try? await saveUserProfile(user)
            }
        }
    }

    private func saveUserProfile(_ user: User) async throws {
        guard let userId = user.id else {
            print("💾 Cannot save user profile - userId is nil")
            return
        }
        print("💾 Saving user profile for: \(userId)")
        print("💾 User displayName: '\(user.displayName ?? "nil")'")
        print("💾 User email: '\(user.email ?? "nil")'")
        try db.collection("users").document(userId).setData(from: user)
        print("💾 Successfully saved user profile to Firestore")
    }

    func updateUserSettings(_ settings: UserSettings) async throws {
        guard let userId = currentUser?.id else { return }
        try await db.collection("users").document(userId).updateData([
            "settings": try Firestore.Encoder().encode(settings)
        ])
        currentUser?.settings = settings
    }

    func updateDisplayName(_ name: String) async throws {
        guard let userId = currentUser?.id else { return }

        // Update Firestore
        try await db.collection("users").document(userId).updateData([
            "displayName": name
        ])

        // Update Firebase Auth profile
        if let user = auth.currentUser {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
        }

        // Update local state
        currentUser?.displayName = name
        print("💾 Updated displayName to: '\(name)'")
    }

    func updateBirthDate(_ date: Date) async throws {
        guard let userId = currentUser?.id else { return }

        try await db.collection("users").document(userId).updateData([
            "birthDate": Timestamp(date: date)
        ])

        currentUser?.birthDate = date
        print("💾 Updated birthDate to: '\(date)'")
    }

    func updateHeight(_ heightCm: Double) async throws {
        guard let userId = currentUser?.id else { return }

        try await db.collection("users").document(userId).updateData([
            "heightCm": heightCm
        ])

        currentUser?.heightCm = heightCm
        print("💾 Updated height to: '\(heightCm)' cm")
    }
}

enum AuthError: LocalizedError {
    case invalidCredential
    case invalidPhoneNumber
    case invalidVerificationCode
    case missingVerificationCode
    case quotaExceeded
    case sessionExpired
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Ogiltiga inloggningsuppgifter"
        case .invalidPhoneNumber: return "Ogiltigt telefonnummer"
        case .invalidVerificationCode: return "Felaktig verifieringskod"
        case .missingVerificationCode: return "Verifieringskod saknas"
        case .quotaExceeded: return "För många försök. Försök igen senare."
        case .sessionExpired: return "Sessionen har gått ut. Försök igen."
        case .networkError: return "Nätverksfel. Kontrollera din anslutning."
        case .unknown(let message): return message
        }
    }

    static func from(_ error: Error) -> AuthError {
        let nsError = error as NSError
        print("🔍 AuthError.from: Converting error")
        print("🔍 AuthError: Domain: \(nsError.domain)")
        print("🔍 AuthError: Code: \(nsError.code)")
        print("🔍 AuthError: Description: \(nsError.localizedDescription)")

        // Firebase Auth errors
        if nsError.domain == "FIRAuthErrorDomain" {
            switch nsError.code {
            case 17010: return .invalidPhoneNumber
            case 17044: return .invalidVerificationCode
            case 17046: return .missingVerificationCode
            case 17051: return .sessionExpired
            case 17065: return .quotaExceeded
            case 17999: return .unknown("APNS token saknas. Kontrollera att enheten är registrerad för notifikationer.")
            case 17028: return .unknown("Ogiltig APNS token-konfiguration. Kontrollera Firebase-inställningarna.")
            case 17005: return .networkError
            default: return .unknown("Firebase Auth fel (kod \(nsError.code)): \(nsError.localizedDescription)")
            }
        }

        // Standard Auth errors
        switch nsError.code {
        case AuthErrorCode.invalidCredential.rawValue: return .invalidCredential
        case AuthErrorCode.invalidPhoneNumber.rawValue: return .invalidPhoneNumber
        case AuthErrorCode.invalidVerificationCode.rawValue: return .invalidVerificationCode
        case AuthErrorCode.missingVerificationCode.rawValue: return .missingVerificationCode
        case AuthErrorCode.quotaExceeded.rawValue: return .quotaExceeded
        case AuthErrorCode.sessionExpired.rawValue: return .sessionExpired
        case AuthErrorCode.networkError.rawValue: return .networkError
        default: return .unknown(error.localizedDescription)
        }
    }
}
