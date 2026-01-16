import SwiftUI

struct AIInsightsView: View {
    @State private var viewModel: AIViewModel
    @State private var selectedInsight: AIInsight?
    @State private var showingChat = false
    @State private var showingDisclaimer = false
    @AppStorage("hasSeenAIDisclaimer") private var hasSeenAIDisclaimer = false

    let userId: String
    let currentHealthData: (SleepData?, ActivityData?, HeartData?)
    let extendedContext: ExtendedHealthContext?

    init(userId: String, currentHealthData: (SleepData?, ActivityData?, HeartData?), extendedContext: ExtendedHealthContext? = nil) {
        self.userId = userId
        self.currentHealthData = currentHealthData
        self.extendedContext = extendedContext
        _viewModel = State(initialValue: AIViewModel(userId: userId))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.vitalyBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        headerSection

                        // Visa alltid snabbåtgärder först
                        quickActionsSection

                        if viewModel.isLoading && viewModel.insights.isEmpty {
                            loadingView
                        } else if viewModel.insights.isEmpty {
                            emptyInsightsMessage
                        } else {
                            insightsListSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
                .scrollBounceBehavior(.basedOnSize)
                .clipped()
                .contentShape(Rectangle())
                .refreshable {
                    await viewModel.refreshInsights()
                }

                if viewModel.isGenerating {
                    generatingOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Insights")
                        .font(.headline)
                        .foregroundStyle(Color.vitalyTextPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showingChat = true
                        } label: {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.vitalyPrimary)
                        }

                        Menu {
                            Button {
                                Task {
                                    await viewModel.generateDailyInsight(
                                        sleep: currentHealthData.0,
                                        activity: currentHealthData.1,
                                        heart: currentHealthData.2
                                    )
                                }
                            } label: {
                                Label("Daily Summary", systemImage: "sun.max.fill")
                            }
                            .disabled(viewModel.isGenerating)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.vitalyPrimary)
                        }
                        .disabled(viewModel.isGenerating)
                    }
                }
            }
            .sheet(item: $selectedInsight) { insight in
                InsightDetailView(insight: insight) {
                    Task {
                        await viewModel.markAsRead(insight)
                    }
                }
            }
            .sheet(isPresented: $showingChat) {
                AIChatView(
                    viewModel: viewModel,
                    healthContext: ExtendedHealthContext(
                        todaySleep: currentHealthData.0,
                        todayActivity: currentHealthData.1,
                        todayHeart: currentHealthData.2,
                        sleepHistory: currentHealthData.0 != nil ? [currentHealthData.0!] : [],
                        activityHistory: currentHealthData.1 != nil ? [currentHealthData.1!] : [],
                        heartHistory: currentHealthData.2 != nil ? [currentHealthData.2!] : []
                    )
                )
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .task {
                // Set extended context for background data (weight, GLP-1, etc)
                viewModel.extendedContext = extendedContext
                await viewModel.loadInsights()
                // Användaren triggar manuellt insikter via snabbåtgärder
            }
            .onAppear {
                if !hasSeenAIDisclaimer {
                    showingDisclaimer = true
                }
            }
            .sheet(isPresented: $showingDisclaimer) {
                AIDisclaimerSheet(hasSeenDisclaimer: $hasSeenAIDisclaimer)
            }
        }
    }

    // MARK: - Header Section
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

            // AI Icon
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

    // MARK: - Insights List Section (bara listan)
    private var insightsListSection: some View {
        VStack(spacing: 16) {
            if viewModel.unreadCount > 0 {
                unreadBanner
            }

            // Insights List
            VStack(alignment: .leading, spacing: 12) {
                Text("LATEST INSIGHTS")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .tracking(1.2)
                    .padding(.horizontal, 4)

                ForEach(viewModel.insights) { insight in
                    InsightRow(insight: insight) {
                        selectedInsight = insight
                    }
                }
            }
        }
    }

    // MARK: - Empty Insights Message (enkel, inte full empty state)
    private var emptyInsightsMessage: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(Color.vitalyTextSecondary.opacity(0.5))

            Text("Choose an action above to generate your first AI insight")
                .font(.subheadline)
                .foregroundStyle(Color.vitalyTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
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
                QuickActionCard(
                    icon: "sun.max.fill",
                    title: "Daily\nSummary",
                    color: .vitalyPrimary
                ) {
                    Task {
                        await viewModel.generateDailyInsight(
                            sleep: currentHealthData.0,
                            activity: currentHealthData.1,
                            heart: currentHealthData.2
                        )
                    }
                }

                QuickActionCard(
                    icon: "moon.stars.fill",
                    title: "Sleep\nAnalysis",
                    color: .vitalySleep
                ) {
                    Task {
                        if let sleep = currentHealthData.0 {
                            await viewModel.generateSleepAnalysis(sleepData: [sleep])
                        }
                    }
                }

                QuickActionCard(
                    icon: "heart.text.square.fill",
                    title: "Recovery\nAdvice",
                    color: .vitalyRecovery
                ) {
                    Task {
                        await viewModel.generateRecoveryAdvice(
                            sleep: currentHealthData.0,
                            heart: currentHealthData.2,
                            recentActivity: currentHealthData.1 != nil ? [currentHealthData.1!] : []
                        )
                    }
                }

                QuickActionCard(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Chat with\nAI",
                    color: .vitalyHeart
                ) {
                    showingChat = true
                }
            }
        }
    }

    // MARK: - Unread Banner
    private var unreadBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient.vitalyGradient)
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("You have \(viewModel.unreadCount) unread insight\(viewModel.unreadCount == 1 ? "" : "s")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text("Tap to read")
                    .font(.caption)
                    .foregroundStyle(Color.vitalyTextSecondary)
            }

            Spacer()

            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundStyle(Color.vitalyPrimary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.vitalyPrimary.opacity(0.3), Color.vitalySecondary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 40)

            ZStack {
                Circle()
                    .fill(LinearGradient.vitalyGradient)
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.vitalyPrimary.opacity(0.3), radius: 20, x: 0, y: 10)

                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: 8) {
                Text("No insights yet")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text("Generate your first AI insight to get personalized health analyses.")
                    .font(.subheadline)
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            Button {
                Task {
                    await viewModel.generateDailyInsight(
                        sleep: currentHealthData.0,
                        activity: currentHealthData.1,
                        heart: currentHealthData.2
                    )
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Generate First Insight")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(LinearGradient.vitalyGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.vitalyPrimary.opacity(0.4), radius: 10, x: 0, y: 5)
            }
            .disabled(viewModel.isGenerating)

            Spacer(minLength: 40)
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

// MARK: - Quick Action Card
struct QuickActionCard: View {
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

// MARK: - Insight Row
struct InsightRow: View {
    let insight: AIInsight
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(typeColor.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: typeIcon)
                        .font(.system(size: 20))
                        .foregroundStyle(typeColor)

                    // Unread indicator
                    if !insight.isRead {
                        Circle()
                            .fill(Color.vitalyPrimary)
                            .frame(width: 10, height: 10)
                            .offset(x: 16, y: -16)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(insight.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .lineLimit(1)

                    Text(insight.content)
                        .font(.caption)
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .lineLimit(2)

                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundStyle(Color.vitalyTextSecondary.opacity(0.7))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.vitalyTextSecondary)
            }
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
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: insight.createdAt, relativeTo: Date())
    }
}

// MARK: - AI Disclaimer Sheet
struct AIDisclaimerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hasSeenDisclaimer: Bool
    @State private var isAccepted = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.vitalyGradient)
                                    .frame(width: 80, height: 80)

                                Image(systemName: "sparkles")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.white)
                            }

                            VStack(spacing: 8) {
                                Text("Before You Begin")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(Color.vitalyTextPrimary)

                                Text("Important information about AI insights")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.vitalyTextSecondary)
                            }
                        }
                        .padding(.top, 20)

                        // Info Cards
                        VStack(spacing: 16) {
                            AIDisclaimerCard(
                                icon: "brain.head.profile",
                                title: "AI-Generated Content",
                                description: "All insights and recommendations are generated by artificial intelligence and may contain inaccuracies.",
                                color: Color.vitalyPrimary
                            )

                            AIDisclaimerCard(
                                icon: "stethoscope",
                                title: "Not Medical Advice",
                                description: "This information is for educational purposes only and should not replace professional medical consultation.",
                                color: Color.vitalyHeart
                            )

                            AIDisclaimerCard(
                                icon: "person.fill.checkmark",
                                title: "Consult Your Doctor",
                                description: "Always consult a qualified healthcare provider before making health decisions based on AI suggestions.",
                                color: Color.vitalySleep
                            )
                        }
                        .padding(.horizontal, 16)

                        // Acceptance Toggle
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isAccepted.toggle()
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isAccepted ? Color.vitalyExcellent : Color.vitalyTextSecondary, lineWidth: 2)
                                        .frame(width: 24, height: 24)

                                    if isAccepted {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.vitalyExcellent)
                                            .frame(width: 18, height: 18)

                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }

                                Text("I understand that AI insights are not medical advice")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.vitalyTextPrimary)
                                    .multilineTextAlignment(.leading)

                                Spacer()
                            }
                            .padding(16)
                            .background(Color.vitalyCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)

                        // Continue Button
                        Button {
                            hasSeenDisclaimer = true
                            dismiss()
                        } label: {
                            Text("Continue")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(isAccepted ? LinearGradient.vitalyGradient : LinearGradient(colors: [Color.vitalySurface], startPoint: .leading, endPoint: .trailing))
                                .foregroundStyle(isAccepted ? .white : Color.vitalyTextSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(!isAccepted)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .clipped()
                .contentShape(Rectangle())
            }
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(!hasSeenDisclaimer)
        }
    }
}

// MARK: - AI Disclaimer Card
struct AIDisclaimerCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.vitalyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview
#Preview {
    AIInsightsView(
        userId: "preview-user",
        currentHealthData: (nil, nil, nil)
    )
}
