import SwiftUI

struct AIInsightsView: View {
    @State private var viewModel: AIViewModel
    @State private var selectedInsight: AIInsight?
    @State private var showingChat = false

    let userId: String
    let currentHealthData: (SleepData?, ActivityData?, HeartData?)

    init(userId: String, currentHealthData: (SleepData?, ActivityData?, HeartData?)) {
        self.userId = userId
        self.currentHealthData = currentHealthData
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

                        if viewModel.isLoading && viewModel.insights.isEmpty {
                            loadingView
                        } else if viewModel.insights.isEmpty {
                            emptyStateView
                        } else {
                            insightsContent
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
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
                    Text("Insikter")
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
                                Label("Daglig sammanfattning", systemImage: "sun.max.fill")
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
                    healthContext: HealthContext(
                        sleep: currentHealthData.0,
                        activity: currentHealthData.1,
                        heart: currentHealthData.2
                    )
                )
            }
            .alert("Fel", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .task {
                await viewModel.loadInsights()
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI-insikter")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text("Personliga analyser av din hälsa")
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

    // MARK: - Insights Content
    private var insightsContent: some View {
        VStack(spacing: 16) {
            if viewModel.unreadCount > 0 {
                unreadBanner
            }

            // Quick Actions
            quickActionsSection

            // Insights List
            VStack(alignment: .leading, spacing: 12) {
                Text("SENASTE INSIKTER")
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

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SNABBÅTGÄRDER")
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
                    title: "Daglig\nsammanfattning",
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
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Chatta med\nAI",
                    color: .vitalySleep
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
                Text("Du har \(viewModel.unreadCount) oläst\(viewModel.unreadCount == 1 ? "" : "a") insikt\(viewModel.unreadCount == 1 ? "" : "er")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text("Tryck för att läsa")
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
                Text("Inga insikter än")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text("Generera din första AI-insikt för att få personliga hälsoanalyser.")
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
                    Text("Generera första insikten")
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

            Text("Laddar insikter...")
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
                    Text("Genererar insikt...")
                        .font(.headline)
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Text("AI analyserar din hälsodata")
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
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: insight.createdAt, relativeTo: Date())
    }
}

// MARK: - Preview
#Preview {
    AIInsightsView(
        userId: "preview-user",
        currentHealthData: (nil, nil, nil)
    )
}
