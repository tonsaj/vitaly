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
                    Label("Overview", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            FitnessView()
                .tabItem {
                    Label("Fitness", systemImage: selectedTab == 1 ? "figure.run" : "figure.run")
                }
                .tag(1)

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: selectedTab == 2 ? "lightbulb.fill" : "lightbulb")
                }
                .tag(2)

            BiologyView()
                .tabItem {
                    Label("Biology", systemImage: selectedTab == 3 ? "heart.fill" : "heart")
                }
                .tag(3)

            SettingsView(authService: coordinator.authService, measurementService: coordinator.bodyMeasurementService, healthKitService: coordinator.healthKitService, glp1Service: coordinator.glp1Service)
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 4 ? "gear" : "gear")
                }
                .tag(4)
        }
        .tint(.vitalyPrimary)
    }
}

// MARK: - Insights View (AI-powered)
struct InsightsView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var viewModel: AIViewModel?
    @State private var selectedInsight: AIInsight?
    @State private var showingChat = false
    @State private var chatHealthContext: ExtendedHealthContext?
    @State private var isLoadingChatContext = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                if let vm = viewModel {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Header
                            headerSection

                            if vm.isLoading && vm.insights.isEmpty {
                                loadingView
                            } else {
                                // Quick Actions
                                quickActionsSection(vm: vm)

                                // Insights List
                                if !vm.insights.isEmpty {
                                    insightsListSection(vm: vm)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                        .frame(maxWidth: .infinity)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .clipped()
                    .contentShape(Rectangle())
                    .refreshable {
                        await vm.refreshInsights()
                    }

                    if vm.isGenerating {
                        generatingOverlay
                    }
                } else {
                    loadingView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let vm = viewModel {
                        Button {
                            showingChat = true
                        } label: {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.vitalyPrimary)
                        }
                    }
                }
            }
            .sheet(item: $selectedInsight) { insight in
                InsightDetailView(
                    insight: insight,
                    onAppear: {
                        Task {
                            await viewModel?.markAsRead(insight)
                        }
                    },
                    onDeepAnalysis: {
                        Task {
                            // Fetch 30 days of data for deep analysis
                            var sleepHistory: [SleepData] = []
                            var activityHistory: [ActivityData] = []
                            var heartHistory: [HeartData] = []

                            for dayOffset in 0..<30 {
                                if let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) {
                                    if let sleep = try? await coordinator.healthKitService.fetchSleepData(for: date) {
                                        sleepHistory.append(sleep)
                                    }
                                    if let activity = try? await coordinator.healthKitService.fetchActivityData(for: date) {
                                        activityHistory.append(activity)
                                    }
                                    if let heart = try? await coordinator.healthKitService.fetchHeartData(for: date) {
                                        heartHistory.append(heart)
                                    }
                                }
                            }

                            let user = coordinator.authService.currentUser
                            let profile = UserHealthProfile(
                                name: user?.displayName,
                                age: user?.age,
                                heightCm: user?.heightCm,
                                weightKg: nil,
                                bodyFatPercentage: nil,
                                vo2Max: nil,
                                leanBodyMass: nil
                            )

                            await viewModel?.generateDeepAnalysis(
                                insightType: insight.type,
                                sleepData: sleepHistory,
                                activityData: activityHistory,
                                heartData: heartHistory,
                                userProfile: profile
                            )
                        }
                    }
                )
            }
            .sheet(isPresented: $showingChat) {
                if let vm = viewModel, let context = chatHealthContext {
                    AIChatView(
                        viewModel: vm,
                        healthContext: context
                    )
                } else if isLoadingChatContext {
                    ZStack {
                        Color.vitalyBackground.ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.vitalyPrimary)
                                .scaleEffect(1.2)
                            Text("Loading health data...")
                                .font(.subheadline)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }
                    }
                }
            }
            .onChange(of: showingChat) { _, isShowing in
                if isShowing && chatHealthContext == nil {
                    Task {
                        await loadChatContext()
                    }
                }
            }
            .task {
                if viewModel == nil {
                    viewModel = AIViewModel(userId: coordinator.authService.currentUser?.id ?? "anonymous")
                }
                await viewModel?.loadInsights()
                // Load extended context (weight, GLP-1, etc) for all AI insights
                if chatHealthContext == nil {
                    await loadChatContext()
                }
            }
        }
    }

    // MARK: - Load Chat Context
    private func loadChatContext() async {
        isLoadingChatContext = true

        var sleepHistory: [SleepData] = []
        var activityHistory: [ActivityData] = []
        var heartHistory: [HeartData] = []

        // Fetch 30 days of health data
        for dayOffset in 0..<30 {
            if let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) {
                if let sleep = try? await coordinator.healthKitService.fetchSleepData(for: date) {
                    sleepHistory.append(sleep)
                }
                if let activity = try? await coordinator.healthKitService.fetchActivityData(for: date) {
                    activityHistory.append(activity)
                }
                if let heart = try? await coordinator.healthKitService.fetchHeartData(for: date) {
                    heartHistory.append(heart)
                }
            }
        }

        // Fetch body measurements (last 30 days)
        await coordinator.bodyMeasurementService.fetchMeasurements(limit: 30)
        let bodyMeasurements = coordinator.bodyMeasurementService.measurements

        // Fetch GLP-1 treatment and injection history
        let glp1Treatment = coordinator.glp1Service.treatment
        let glp1Injections = coordinator.glp1Service.medicationLogs

        // Build user profile
        let user = coordinator.authService.currentUser
        let userProfile = UserHealthProfile(
            name: user?.displayName,
            age: user?.age,
            heightCm: user?.heightCm,
            weightKg: bodyMeasurements.first?.weight,
            bodyFatPercentage: nil,
            vo2Max: nil,
            leanBodyMass: nil
        )

        chatHealthContext = ExtendedHealthContext(
            todaySleep: sleepHistory.first,
            todayActivity: activityHistory.first,
            todayHeart: heartHistory.first,
            sleepHistory: sleepHistory,
            activityHistory: activityHistory,
            heartHistory: heartHistory,
            bodyMeasurements: bodyMeasurements,
            glp1Treatment: glp1Treatment,
            glp1Injections: glp1Injections,
            userProfile: userProfile
        )

        // Set extended context on viewModel so all AI insights have access to background data
        viewModel?.extendedContext = chatHealthContext

        isLoadingChatContext = false
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Insights")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text("Personal analyses of your health")
                    .font(.subheadline)
                    .foregroundStyle(Color.vitalyTextSecondary)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(LinearGradient.vitalyGradient)
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    // MARK: - Quick Actions
    private func quickActionsSection(vm: AIViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK ACTIONS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vitalyTextSecondary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                InsightQuickActionCard(
                    icon: "sun.max.fill",
                    title: "Daily\nSummary",
                    color: .vitalyPrimary
                ) {
                    Task {
                        // Fetch fresh data before generating insight
                        let sleep = try? await coordinator.healthKitService.fetchSleepData(for: Date())
                        let activity = try? await coordinator.healthKitService.fetchActivityData(for: Date())
                        let heart = try? await coordinator.healthKitService.fetchHeartData(for: Date())
                        await vm.generateDailyInsight(
                            sleep: sleep,
                            activity: activity,
                            heart: heart
                        )
                    }
                }

                InsightQuickActionCard(
                    icon: "moon.stars.fill",
                    title: "Sleep\nAnalysis",
                    color: .vitalySleep
                ) {
                    Task {
                        if let sleep = try? await coordinator.healthKitService.fetchSleepData(for: Date()) {
                            await vm.generateSleepAnalysis(sleepData: [sleep])
                        }
                    }
                }

                InsightQuickActionCard(
                    icon: "heart.text.square.fill",
                    title: "Recovery\nAdvice",
                    color: .vitalyRecovery
                ) {
                    Task {
                        let sleep = try? await coordinator.healthKitService.fetchSleepData(for: Date())
                        let activity = try? await coordinator.healthKitService.fetchActivityData(for: Date())
                        let heart = try? await coordinator.healthKitService.fetchHeartData(for: Date())
                        await vm.generateRecoveryAdvice(
                            sleep: sleep,
                            heart: heart,
                            recentActivity: activity != nil ? [activity!] : []
                        )
                    }
                }

                InsightQuickActionCard(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Chat with\nAI",
                    color: .vitalyHeart
                ) {
                    showingChat = true
                }
            }
        }
    }

    // MARK: - Insights List
    private func insightsListSection(vm: AIViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LATEST INSIGHTS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vitalyTextSecondary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            ForEach(vm.insights) { insight in
                InsightRowCard(
                    insight: insight,
                    action: {
                        selectedInsight = insight
                    }
                )
            }
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 80)

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .vitalyPrimary))
                .scaleEffect(1.2)

            Text("Loading insights...")
                .font(.subheadline)
                .foregroundStyle(Color.vitalyTextSecondary)

            Spacer(minLength: 80)
        }
    }

    // MARK: - Generating Overlay
    private var generatingOverlay: some View {
        ZStack {
            Color.vitalyBackground.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.vitalyGradient)
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.vitalyPrimary.opacity(0.4), radius: 20, x: 0, y: 10)

                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.4)
                }

                VStack(spacing: 8) {
                    Text("Generating insight...")
                        .font(.headline)
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Text("AI is analyzing your health data")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.vitalyCardBackground)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
        }
    }
}

// MARK: - Insight Quick Action Card
struct InsightQuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.vitalyTextPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.vitalyCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Insight Row Card
struct InsightRowCard: View {
    let insight: AIInsight
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 14) {
                    // Header with icon, title and date
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(typeColor.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: typeIcon)
                                .font(.system(size: 18))
                                .foregroundStyle(typeColor)

                            if !insight.isRead {
                                Circle()
                                    .fill(Color.vitalyPrimary)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 14, y: -14)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(insight.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.vitalyTextPrimary)
                                .lineLimit(1)

                            // Date badge
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(formattedDate)
                                    .font(.caption2.weight(.medium))
                            }
                            .foregroundStyle(typeColor.opacity(0.8))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.vitalyTextSecondary.opacity(0.5))
                    }

                    // Content preview with sparkle icon
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundStyle(typeColor.opacity(0.6))
                            .padding(.top, 2)

                        Text(insight.content)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.vitalyTextPrimary.opacity(0.9))
                            .lineLimit(3)
                            .lineSpacing(3)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(typeColor.opacity(0.05))
                    )
                }
                .padding(16)
                .padding(.bottom, 0)
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.vitalyCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(typeColor.opacity(0.1), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var typeIcon: String {
        switch insight.type {
        case .dailySummary: return "sun.max.fill"
        case .sleepAnalysis: return "moon.fill"
        case .activityTrend: return "chart.line.uptrend.xyaxis"
        case .recoveryAdvice: return "battery.100.bolt"
        case .heartHealth: return "heart.fill"
        case .weeklyReport: return "calendar"
        }
    }

    private var typeColor: Color {
        switch insight.type {
        case .dailySummary: return .vitalyPrimary
        case .sleepAnalysis: return .vitalySleep
        case .activityTrend: return .vitalyActivity
        case .recoveryAdvice: return .vitalyRecovery
        case .heartHealth: return .vitalyHeart
        case .weeklyReport: return .vitalyExcellent
        }
    }

    private var formattedDate: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(insight.createdAt) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "Today at \(formatter.string(from: insight.createdAt))"
        } else if calendar.isDateInYesterday(insight.createdAt) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "Yesterday at \(formatter.string(from: insight.createdAt))"
        } else if let daysAgo = calendar.dateComponents([.day], from: insight.createdAt, to: now).day, daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "EEEE 'at' HH:mm"
            return formatter.string(from: insight.createdAt)
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "MMM d 'at' HH:mm"
            return formatter.string(from: insight.createdAt)
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
