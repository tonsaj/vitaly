import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var selectedTab = 0

    init() {
        // Configure tab bar appearance for dark theme
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.vitalyCardBackground)

        // Selected tab color
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.vitalyPrimary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.vitalyPrimary)
        ]

        // Unselected tab color
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.vitalyTextSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.vitalyTextSecondary)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Översikt", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            InsightsView()
                .tabItem {
                    Label("Insikter", systemImage: selectedTab == 1 ? "lightbulb.fill" : "lightbulb")
                }
                .tag(1)

            SettingsView(authService: coordinator.authService)
                .tabItem {
                    Label("Inställningar", systemImage: selectedTab == 2 ? "gear" : "gear")
                }
                .tag(2)
        }
        .tint(.vitalyPrimary)
    }
}

// MARK: - Insights Placeholder View
struct InsightsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Insikter")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(Color.vitalyTextPrimary)

                            Text("AI-driven hälsoanalys")
                                .font(.subheadline)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                        // Coming soon card
                        VitalyHeroCard {
                            VStack(spacing: 20) {
                                SimpleSunburstIcon(color: .white)
                                    .frame(width: 60, height: 60)

                                VStack(spacing: 8) {
                                    Text("Kommer snart")
                                        .font(.title2.weight(.semibold))
                                        .foregroundStyle(.white)

                                    Text("AI-drivna insikter och personliga rekommendationer baserat på din hälsodata")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.9))
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                        }

                        // Feature preview cards
                        VStack(spacing: 16) {
                            FeaturePreviewCard(
                                icon: "brain.head.profile",
                                title: "Smart analys",
                                description: "Upptäck mönster i din hälsodata",
                                color: .vitalyPrimary
                            )

                            FeaturePreviewCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Trender & prognoser",
                                description: "Se hur din hälsa utvecklas över tid",
                                color: .vitalySecondary
                            )

                            FeaturePreviewCard(
                                icon: "bell.badge.fill",
                                title: "Personliga tips",
                                description: "Få anpassade råd för bättre hälsa",
                                color: .vitalyAccent
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SimpleSunburstIcon(color: .vitalyPrimary)
                        .frame(width: 28, height: 28)
                }
            }
        }
    }
}

// MARK: - Feature Preview Card
struct FeaturePreviewCard: View {
    let icon: String
    let title: String
    let description: String
    var color: Color = .vitalyPrimary

    var body: some View {
        VitalyCard(cornerRadius: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(Color.vitalyTextSecondary)
                }

                Spacer()
            }
            .padding(16)
        }
    }
}

// MARK: - Preview
#Preview("Main Tab View") {
    MainTabView()
        .environmentObject(AppCoordinator())
}

#Preview("Insights") {
    InsightsView()
}

#Preview("Dark Mode") {
    MainTabView()
        .environmentObject(AppCoordinator())
        .preferredColorScheme(.dark)
}
