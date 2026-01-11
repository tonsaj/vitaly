import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices

@MainActor
final class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: AuthError?

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?

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
            }
        }
    }

    // MARK: - Phone Authentication
    func sendVerificationCode(phoneNumber: String) async throws -> String {
        isLoading = true
        defer { isLoading = false }

        do {
            let verificationID = try await PhoneAuthProvider.provider()
                .verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            return verificationID
        } catch {
            self.error = AuthError.from(error)
            throw error
        }
    }

    func verifyCode(verificationID: String, code: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let credential = PhoneAuthProvider.provider()
                .credential(withVerificationID: verificationID, verificationCode: code)
            let result = try await auth.signIn(with: credential)

            // Check if user exists, otherwise create new profile
            let userDoc = try await db.collection("users").document(result.user.uid).getDocument()

            if !userDoc.exists {
                let user = User(
                    id: result.user.uid,
                    phoneNumber: result.user.phoneNumber ?? "",
                    displayName: nil,
                    createdAt: Date()
                )
                try await saveUserProfile(user)
                currentUser = user
            } else {
                await fetchUserProfile(userId: result.user.uid)
            }
        } catch {
            self.error = AuthError.from(error)
            throw error
        }
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        isLoading = true
        defer { isLoading = false }

        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidCredential
        }

        let oAuthCredential = OAuthProvider.appleCredential(
            withIDToken: tokenString,
            rawNonce: nil,
            fullName: credential.fullName
        )

        do {
            let result = try await auth.signIn(with: oAuthCredential)

            // Check if user exists
            let userDoc = try await db.collection("users").document(result.user.uid).getDocument()

            if !userDoc.exists {
                let displayName = [credential.fullName?.givenName, credential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")

                let user = User(
                    id: result.user.uid,
                    phoneNumber: result.user.phoneNumber ?? "",
                    displayName: displayName.isEmpty ? nil : displayName,
                    createdAt: Date()
                )
                try await saveUserProfile(user)
                currentUser = user
            } else {
                await fetchUserProfile(userId: result.user.uid)
            }
        } catch {
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
            currentUser = try document.data(as: User.self)
        } catch {
            // Create basic profile if doesn't exist
            if let firebaseUser = auth.currentUser {
                currentUser = User(
                    id: firebaseUser.uid,
                    phoneNumber: firebaseUser.phoneNumber ?? "",
                    displayName: firebaseUser.displayName,
                    createdAt: Date()
                )
            }
        }
    }

    private func saveUserProfile(_ user: User) async throws {
        guard let userId = user.id else { return }
        try db.collection("users").document(userId).setData(from: user)
    }

    func updateUserSettings(_ settings: UserSettings) async throws {
        guard let userId = currentUser?.id else { return }
        try await db.collection("users").document(userId).updateData([
            "settings": try Firestore.Encoder().encode(settings)
        ])
        currentUser?.settings = settings
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
