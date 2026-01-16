import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

// MARK: - App Delegate for Firebase Phone Auth
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Register for remote notifications (required for phone auth)
        application.registerForRemoteNotifications()

        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Handle Google Sign-In
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }

        // Handle Firebase Auth
        if Auth.auth().canHandle(url) {
            return true
        }
        return false
    }

    // Handle remote notification registration
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        #if DEBUG
        print("📱 Phone Auth: Registering APNS token (sandbox)")
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
        #else
        print("📱 Phone Auth: Registering APNS token (production)")
        Auth.auth().setAPNSToken(deviceToken, type: .prod)
        #endif

        // Log token for debugging
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("📱 Phone Auth: Device token: \(token)")
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Phone Auth: Failed to register for remote notifications: \(error.localizedDescription)")
        print("❌ Phone Auth: Error details: \(error)")
    }

    // Handle incoming notifications for phone auth
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📱 Phone Auth: Received remote notification: \(userInfo)")

        if Auth.auth().canHandleNotification(userInfo) {
            print("📱 Phone Auth: Firebase Auth handled the notification")
            completionHandler(.noData)
            return
        }

        print("📱 Phone Auth: Notification not handled by Firebase Auth")
        completionHandler(.noData)
    }
}

@main
struct VitalyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appCoordinator = AppCoordinator()

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appCoordinator)
                .preferredColorScheme(.dark)
        }
    }

    private func configureAppearance() {
        // Dark theme navigation bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.vitalyBackground)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(Color.vitalyPrimary)

        // Tab bar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Color.vitalyBackground)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}

struct RootView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        Group {
            switch coordinator.authState {
            case .unknown:
                SplashView()
            case .unauthenticated:
                AuthNavigationView()
            case .onboarding:
                OnboardingView()
            case .authenticated, .guest:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.authState)
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            // Background - matches launch screen
            Color.vitalyBackground
                .ignoresSafeArea()

            // Simple centered content
            VStack(spacing: 16) {
                // Sunburst icon
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.vitalyPrimary)

                Text("Vitaly")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.vitalyTextPrimary)
            }
        }
    }
}

#Preview {
    SplashView()
}
