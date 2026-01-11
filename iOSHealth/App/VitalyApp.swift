import SwiftUI
import FirebaseCore
import FirebaseAuth

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
        if Auth.auth().canHandle(url) {
            return true
        }
        return false
    }

    // Handle remote notification registration
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // Handle incoming notifications for phone auth
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
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
            case .authenticated:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.authState)
    }
}

struct SplashView: View {
    @State private var waveOffset: CGFloat = 0
    @State private var showContent = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Background
            Color.vitalyBackground
                .ignoresSafeArea()

            // Animated wave/curve
            SplashWaveShape(offset: waveOffset)
                .fill(LinearGradient.vitalyHeroGradient)
                .frame(height: 400)
                .offset(y: -100)
                .blur(radius: 1)

            // Content
            VStack(spacing: 32) {
                Spacer()

                // Sunburst icon
                SplashSunburstIcon()
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseScale)

                VStack(spacing: 8) {
                    Text("Vitaly")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Text("Din hälsa, förenklad")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextSecondary)
                }

                Spacer()

                // Loading indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.vitalyPrimary)
                            .frame(width: 8, height: 8)
                            .opacity(showContent ? 1 : 0.3)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: showContent
                            )
                    }
                }
                .padding(.bottom, 60)
            }
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                waveOffset = 50
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}

// MARK: - Splash Wave Shape

struct SplashWaveShape: Shape {
    var offset: CGFloat

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.5

        path.move(to: CGPoint(x: 0, y: height))

        // Create organic flowing curve
        path.addLine(to: CGPoint(x: 0, y: midHeight + offset))

        path.addCurve(
            to: CGPoint(x: width * 0.4, y: midHeight - 50 + offset),
            control1: CGPoint(x: width * 0.15, y: midHeight - 30 + offset),
            control2: CGPoint(x: width * 0.3, y: midHeight - 80 + offset)
        )

        path.addCurve(
            to: CGPoint(x: width * 0.7, y: midHeight + 30 - offset),
            control1: CGPoint(x: width * 0.5, y: midHeight - 20 + offset),
            control2: CGPoint(x: width * 0.6, y: midHeight + 60 - offset)
        )

        path.addCurve(
            to: CGPoint(x: width, y: midHeight - 40 + offset),
            control1: CGPoint(x: width * 0.85, y: midHeight - offset),
            control2: CGPoint(x: width * 0.95, y: midHeight - 60 + offset)
        )

        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Splash Sunburst Icon

struct SplashSunburstIcon: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Outer rays
            ForEach(0..<12) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.vitalyTextPrimary.opacity(0.9))
                    .frame(width: 3, height: index % 2 == 0 ? 12 : 8)
                    .offset(y: -30)
                    .rotationEffect(.degrees(Double(index) * 30))
            }

            // Inner circle of dots
            ForEach(0..<8) { index in
                Circle()
                    .fill(Color.vitalyTextPrimary)
                    .frame(width: 4, height: 4)
                    .offset(y: -18)
                    .rotationEffect(.degrees(Double(index) * 45 + 22.5))
            }

            // Center dot
            Circle()
                .fill(Color.vitalyTextPrimary)
                .frame(width: 6, height: 6)
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

#Preview {
    SplashView()
}
