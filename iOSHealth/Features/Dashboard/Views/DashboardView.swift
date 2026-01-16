import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var viewModel = DashboardViewModel()
    @State private var selectedMetric: DashboardMetric?
    private let healthRef = HealthReferenceService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Deep black background
                LinearGradient(
                    colors: [
                        Color.vitalyBackground,
                        Color(red: 0.06, green: 0.06, blue: 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    // Prevent horizontal scroll
                    VStack(spacing: 0) {
                        // Wavy animated header with swipe gesture and arrows for date navigation
                        WavyHeaderView(
                            title: viewModel.dateDisplayText,
                            subtitle: viewModel.todayDate,
                            canGoBack: viewModel.canGoBack,
                            canGoForward: viewModel.canGoForward,
                            onSwipeLeft: {
                                if viewModel.canGoForward {
                                    viewModel.goToNextDay()
                                }
                            },
                            onSwipeRight: {
                                if viewModel.canGoBack {
                                    viewModel.goToPreviousDay()
                                }
                            }
                        )

                        // "Back to today" button if not today
                        if !viewModel.isToday {
                            Button {
                                viewModel.goToToday()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.caption.weight(.semibold))
                                    Text("Back to today")
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(Color.vitalyPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.vitalyPrimary.opacity(0.15))
                                )
                            }
                            .padding(.top, 8)
                        }

                        if viewModel.isLoading {
                            loadingView
                        } else if let error = viewModel.error {
                            errorView(error)
                        } else if viewModel.hasData {
                            VStack(spacing: 20) {
                                // Today's summary with comparison
                                dailySummaryCard

                                // Health metrics (6 cards with navigation)
                                healthMetricsSection

                                // 7-day trend
                                weeklyTrendSection

                                // Activity timeline
                                activityTimelineSection
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            .padding(.bottom, 100)
                        } else {
                            emptyStateView
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollContentBackground(.hidden)
                .clipped()
                .contentShape(Rectangle())
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Update user profile with name for personalized AI
                if let user = coordinator.authService.currentUser {
                    viewModel.updateUserProfile(
                        name: user.displayName,
                        age: user.age,
                        heightCm: user.heightCm,
                        weightKg: nil,
                        bodyFatPercentage: nil,
                        vo2Max: nil
                    )
                }
                await viewModel.loadTodayData()
            }
            .sheet(item: $selectedMetric) { metric in
                MetricDetailSheet(
                    metric: metric,
                    currentValue: currentValue(for: metric),
                    yesterdayValue: yesterdayValue(for: metric),
                    weekData: weekData(for: metric),
                    sleepData: metric == .sleep ? viewModel.sleepData : nil,
                    yesterdaySleepData: metric == .sleep ? viewModel.yesterdayData?.sleep : nil,
                    weeklySleepData: metric == .sleep ? (viewModel.weeklyData?.sleepData ?? []) : []
                )
            }
        }
    }


    // MARK: - Today's Summary
    private var dailySummaryCard: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyPrimary)
                        Text("TODAY'S STATUS")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.vitalyTextSecondary)
                            .tracking(1.2)
                    }

                    Spacer()

                    // Status indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(statusText)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(statusColor)
                    }
                }

                // AI summary or fallback
                if viewModel.isLoadingAI {
                    HStack(spacing: 10) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .vitalyPrimary))
                            .scaleEffect(0.8)
                        Text("Analyzing your health data...")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if let aiSummary = viewModel.aiSummary {
                    Text(aiSummary)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .lineSpacing(4)
                } else {
                    Text(summaryMessage)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .lineSpacing(4)
                }

                // Comparison with yesterday
                Divider()
                    .background(Color.vitalySurface)

                HStack(spacing: 20) {
                    ComparisonItem(
                        label: "Sleep",
                        todayValue: viewModel.sleepData?.formattedDuration ?? "-",
                        change: sleepChange,
                        icon: "bed.double.fill"
                    )

                    ComparisonItem(
                        label: "Steps",
                        todayValue: "\(viewModel.activityData?.steps ?? 0)",
                        change: stepsChange,
                        icon: "figure.walk"
                    )

                    ComparisonItem(
                        label: "HRV",
                        todayValue: "\(Int(viewModel.heartData?.hrv ?? 0)) ms",
                        change: hrvChange,
                        icon: "waveform.path.ecg"
                    )
                }
            }
            .padding(20)
        }
    }

    // MARK: - Health Metrics (6 cards)
    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Metrics")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.vitalyTextPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                // Sleep - Enhanced card with REM and Deep sleep
                SleepMetricCard(
                    sleepData: viewModel.sleepData,
                    evaluation: viewModel.sleepData != nil ? healthRef.evaluateSleep(hours: viewModel.sleepData!.totalHours) : nil
                ) {
                    selectedMetric = .sleep
                }

                // Steps
                TappableMetricCard(
                    icon: "figure.walk",
                    label: "Steps",
                    value: viewModel.activityData != nil ? "\(viewModel.activityData!.steps)" : "--",
                    unit: "",
                    hasData: viewModel.activityData != nil,
                    color: .vitalyActivity,
                    evaluation: viewModel.activityData != nil ? healthRef.evaluateSteps(viewModel.activityData!.steps) : nil
                ) {
                    selectedMetric = .steps
                }

                // RR (Respiratory Rate) - hardcoded until HealthKit supports it
                TappableMetricCard(
                    icon: "lungs.fill",
                    label: "RR",
                    value: "13.1",
                    unit: "rpm",
                    hasData: true,
                    color: .vitalySleep,
                    evaluation: healthRef.evaluateRespiratoryRate(13.1)
                ) {
                    selectedMetric = .respiratoryRate
                }

                // RHR (Resting Heart Rate)
                TappableMetricCard(
                    icon: "heart.fill",
                    label: "RHR",
                    value: viewModel.heartData != nil ? String(format: "%.0f", viewModel.heartData!.restingHeartRate) : "--",
                    unit: "bpm",
                    hasData: viewModel.heartData != nil && viewModel.heartData!.restingHeartRate > 0,
                    color: .vitalyHeart,
                    evaluation: viewModel.heartData != nil ? healthRef.evaluateRestingHeartRate(viewModel.heartData!.restingHeartRate) : nil
                ) {
                    selectedMetric = .restingHeartRate
                }

                // HRV
                TappableMetricCard(
                    icon: "waveform.path.ecg",
                    label: "HRV",
                    value: viewModel.heartData?.hrv != nil ? String(format: "%.0f", viewModel.heartData!.hrv!) : "--",
                    unit: "ms",
                    hasData: viewModel.heartData?.hrv != nil,
                    color: .vitalyRecovery,
                    evaluation: viewModel.heartData?.hrv != nil ? healthRef.evaluateHRV(viewModel.heartData!.hrv!) : nil
                ) {
                    selectedMetric = .hrv
                }

                // SpO2 - hardcoded until HealthKit supports it
                TappableMetricCard(
                    icon: "drop.fill",
                    label: "SpO2",
                    value: "98",
                    unit: "%",
                    hasData: true,
                    color: .vitalyPrimary,
                    evaluation: healthRef.evaluateOxygenSaturation(98)
                ) {
                    selectedMetric = .oxygenSaturation
                }
            }
        }
    }

    // MARK: - 7-day Trend
    private var weeklyTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Last 7 Days")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Spacer()

                Text("Overview")
                    .font(.subheadline)
                    .foregroundStyle(Color.vitalyTextSecondary)
            }

            VitalyCard {
                VStack(spacing: 16) {
                    // Mini trend chart
                    WeeklyTrendChart(data: viewModel.weeklyTrendData)
                        .frame(height: 120)

                    // Weekly statistics
                    HStack(spacing: 0) {
                        WeekStatItem(
                            label: "Avg Sleep",
                            value: viewModel.averageSleepHours,
                            unit: "h",
                            trend: .up
                        )

                        Divider()
                            .frame(height: 40)
                            .background(Color.vitalySurface)

                        WeekStatItem(
                            label: "Avg Steps",
                            value: Double(viewModel.averageSteps),
                            unit: "",
                            trend: .stable
                        )

                        Divider()
                            .frame(height: 40)
                            .background(Color.vitalySurface)

                        WeekStatItem(
                            label: "Avg HRV",
                            value: viewModel.averageHRV,
                            unit: "ms",
                            trend: .down
                        )
                    }
                }
                .padding(20)
            }
        }
    }

    // MARK: - Activity Timeline
    private var activityTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activities Today")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.vitalyTextPrimary)

            if let workouts = viewModel.activityData?.workouts, !workouts.isEmpty {
                VStack(spacing: 0) {
                    ForEach(workouts) { workout in
                        ActivityTimelineRow(workout: workout)

                        if workout.id != workouts.last?.id {
                            Divider()
                                .background(Color.vitalySurface)
                        }
                    }
                }
                .background(Color.vitalyCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
            } else {
                VitalyCard {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.vitalyPrimary.opacity(0.15))
                                .frame(width: 50, height: 50)

                            Image(systemName: "figure.run")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.vitalyPrimary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("No activity yet")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.vitalyTextPrimary)

                            Text("Your workouts will appear here")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }

                        Spacer()
                    }
                    .padding(16)
                }
            }
        }
    }

    // MARK: - Loading & Error Views
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .vitalyPrimary))
                .scaleEffect(1.2)

            Text("Loading health data...")
                .font(.subheadline)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 100)
    }

    private var emptyStateView: some View {
        VitalyCard {
            VStack(spacing: 16) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.vitalyPrimary)

                Text("No data yet")
                    .font(.headline)
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text("Connect to HealthKit to start tracking your health.")
                    .font(.subheadline)
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
        .padding(.horizontal, 16)
        .padding(.top, 40)
    }

    private func errorView(_ error: Error) -> some View {
        VitalyCard {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.vitalyAccent)

                Text("Could not load data")
                    .font(.headline)
                    .foregroundStyle(Color.vitalyTextPrimary)

                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient.vitalyGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(24)
        }
        .padding(.horizontal, 16)
        .padding(.top, 40)
    }

    // MARK: - Computed Properties
    private var statusColor: Color {
        let score = viewModel.overallScore
        if score >= 80 { return .vitalyExcellent }
        if score >= 60 { return .vitalyFair }
        return .vitalyHeart
    }

    private var statusText: String {
        let score = viewModel.overallScore
        if score >= 80 { return "Excellent" }
        if score >= 60 { return "Good" }
        return "Rest recommended"
    }

    private var summaryMessage: String {
        guard viewModel.hasData else { return "Loading..." }

        let sleep = viewModel.sleepData
        let hrv = viewModel.heartData?.hrv ?? 0

        if let s = sleep, s.totalHours >= 7 && hrv >= 50 {
            return "You slept well and your body shows good recovery. A perfect day for activity!"
        } else if let s = sleep, s.totalHours < 6 {
            return "Your sleep was shorter than recommended. Prioritize rest and avoid intense training today."
        } else {
            return "Your body is recovering. Listen to how you feel and adjust today's activity accordingly."
        }
    }

    private var sleepChange: Double {
        viewModel.sleepChange
    }

    private var stepsChange: Double {
        Double(viewModel.stepsChange)
    }

    private var hrvChange: Double {
        viewModel.hrvChange
    }

    // Helper for MetricDetailSheet
    private func currentValue(for metric: DashboardMetric) -> Double {
        switch metric {
        case .sleep: return viewModel.sleepData?.totalHours ?? 0
        case .steps: return Double(viewModel.activityData?.steps ?? 0)
        case .respiratoryRate: return 13.1
        case .restingHeartRate: return viewModel.heartData?.restingHeartRate ?? 0
        case .hrv: return viewModel.heartData?.hrv ?? 0
        case .oxygenSaturation: return 98
        }
    }

    private func yesterdayValue(for metric: DashboardMetric) -> Double {
        switch metric {
        case .sleep: return viewModel.yesterdaySleepHours
        case .steps: return Double(viewModel.yesterdaySteps)
        case .respiratoryRate: return 12.8 // Not available in HealthKit
        case .restingHeartRate: return viewModel.yesterdayData?.heart.restingHeartRate ?? 60
        case .hrv: return viewModel.yesterdayHRV
        case .oxygenSaturation: return 97 // Not available on all devices
        }
    }

    private func weekData(for metric: DashboardMetric) -> [Double] {
        guard let weekly = viewModel.weeklyData else {
            // Fallback if no data available
            switch metric {
            case .sleep: return [7.2, 6.5, 7.8, 6.9, 7.5, 8.0, viewModel.sleepData?.totalHours ?? 7.3]
            case .steps: return [8500, 10200, 7800, 9100, 8900, 11000, Double(viewModel.activityData?.steps ?? 8500)]
            case .respiratoryRate: return [13.0, 12.8, 13.2, 13.1, 12.9, 13.0, 13.1]
            case .restingHeartRate: return [58, 60, 57, 59, 58, 56, viewModel.heartData?.restingHeartRate ?? 58]
            case .hrv: return [52, 48, 55, 50, 53, 58, viewModel.heartData?.hrv ?? 55]
            case .oxygenSaturation: return [97, 98, 98, 97, 98, 99, 98]
            }
        }

        switch metric {
        case .sleep:
            return weekly.sleepData.map { $0?.totalHours ?? 0 }
        case .steps:
            return weekly.activityData.map { Double($0.steps) }
        case .respiratoryRate:
            return [13.0, 12.8, 13.2, 13.1, 12.9, 13.0, 13.1] // Not available
        case .restingHeartRate:
            return weekly.heartData.map { $0.restingHeartRate ?? 60 }
        case .hrv:
            return weekly.heartData.map { $0.hrv ?? 50 }
        case .oxygenSaturation:
            return [97, 98, 98, 97, 98, 99, 98] // Not available on all devices
        }
    }
}

// MARK: - Dashboard Metric Type
enum DashboardMetric: String, Identifiable {
    case sleep, steps, respiratoryRate, restingHeartRate, hrv, oxygenSaturation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sleep: return "Sleep"
        case .steps: return "Steps"
        case .respiratoryRate: return "Respiratory Rate"
        case .restingHeartRate: return "Resting Heart Rate"
        case .hrv: return "Heart Rate Variability"
        case .oxygenSaturation: return "Oxygen Saturation"
        }
    }

    var unit: String {
        switch self {
        case .sleep: return "hours"
        case .steps: return "steps"
        case .respiratoryRate: return "rpm"
        case .restingHeartRate: return "bpm"
        case .hrv: return "ms"
        case .oxygenSaturation: return "%"
        }
    }

    var icon: String {
        switch self {
        case .sleep: return "bed.double.fill"
        case .steps: return "figure.walk"
        case .respiratoryRate: return "lungs.fill"
        case .restingHeartRate: return "heart.fill"
        case .hrv: return "waveform.path.ecg"
        case .oxygenSaturation: return "drop.fill"
        }
    }

    var color: Color {
        switch self {
        case .sleep: return .vitalySleep
        case .steps: return .vitalyActivity
        case .respiratoryRate: return .vitalySleep
        case .restingHeartRate: return .vitalyHeart
        case .hrv: return .vitalyRecovery
        case .oxygenSaturation: return .vitalyPrimary
        }
    }
}

// MARK: - Supporting Views
struct ComparisonItem: View {
    let label: String
    let todayValue: String
    let change: Double
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.vitalyTextSecondary)

            Text(todayValue)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.vitalyTextPrimary)

            HStack(spacing: 2) {
                Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 10))
                Text(changeText)
                    .font(.system(size: 11))
            }
            .foregroundStyle(change >= 0 ? Color.vitalyExcellent : Color.vitalyHeart)
        }
        .frame(maxWidth: .infinity)
    }

    private var changeText: String {
        if abs(change) >= 1000 {
            return String(format: "%.1fk", change / 1000)
        }
        return String(format: "%.0f", abs(change))
    }
}

struct TappableMetricCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let hasData: Bool
    let color: Color
    let evaluation: MetricEvaluation?
    let action: () -> Void

    init(icon: String, label: String, value: String, unit: String, hasData: Bool, color: Color, evaluation: MetricEvaluation? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.value = value
        self.unit = unit
        self.hasData = hasData
        self.color = color
        self.evaluation = evaluation
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: icon)
                                .font(.system(size: 14))
                                .foregroundStyle(color)

                            Text(label)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(color)
                        }

                        if hasData {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(value)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.vitalyTextPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)

                                if !unit.isEmpty {
                                    Text(unit)
                                        .font(.caption)
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                }
                            }
                        } else {
                            Text("--")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.vitalyTextSecondary.opacity(0.6))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)

                        if let eval = evaluation, hasData {
                            HealthStatusIndicator(evaluation: eval)
                        }
                    }
                }
                .padding(16)

                // Simple color bar at bottom (always show for consistent height)
                Capsule()
                    .fill(hasData && evaluation != nil ? evaluation!.color : Color.clear)
                    .frame(height: 3)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
            }
            .frame(minHeight: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.vitalyCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Enhanced Sleep Card with REM and Deep Sleep
struct SleepMetricCard: View {
    let sleepData: SleepData?
    let evaluation: MetricEvaluation?
    let action: () -> Void

    private var hasData: Bool { sleepData != nil }

    private var deepSleepMinutes: Int {
        guard let sleep = sleepData else { return 0 }
        return Int(sleep.deepSleep / 60)
    }

    private var remSleepMinutes: Int {
        guard let sleep = sleepData else { return 0 }
        return Int(sleep.remSleep / 60)
    }

    private var deepSleepPercent: Int {
        guard let sleep = sleepData, sleep.totalDuration > 0 else { return 0 }
        return Int((sleep.deepSleep / sleep.totalDuration) * 100)
    }

    private var remSleepPercent: Int {
        guard let sleep = sleepData, sleep.totalDuration > 0 else { return 0 }
        return Int((sleep.remSleep / sleep.totalDuration) * 100)
    }

    // Goal indicators
    private var isDeepSleepGood: Bool { deepSleepPercent >= 15 }
    private var isRemSleepGood: Bool { remSleepPercent >= 20 }
    private var sleepGoalPercent: Int {
        guard let sleep = sleepData else { return 0 }
        return min(100, Int((sleep.totalHours / 8.0) * 100))
    }

    private func formatMinutesToHoursAndMinutes(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(mins)m"
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "bed.double.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.vitalySleep)

                            Text("Sleep")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.vitalySleep)
                        }

                        if hasData {
                            Text(sleepData?.formattedDuration ?? "--")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.vitalyTextPrimary)
                        } else {
                            Text("--")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.vitalyTextSecondary.opacity(0.6))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)

                        if let eval = evaluation, hasData {
                            HealthStatusIndicator(evaluation: eval)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

                // Sleep stages - compact row
                if hasData {
                    HStack(spacing: 12) {
                        // Deep sleep
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(red: 0.4, green: 0.3, blue: 0.7))
                                .frame(width: 6, height: 6)
                            Text("Deep \(formatMinutesToHoursAndMinutes(deepSleepMinutes))")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.vitalyTextSecondary)
                            if isDeepSleepGood {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(Color.vitalyExcellent)
                            }
                        }

                        // REM sleep
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.vitalySleep)
                                .frame(width: 6, height: 6)
                            Text("REM \(formatMinutesToHoursAndMinutes(remSleepMinutes))")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.vitalyTextSecondary)
                            if isRemSleepGood {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(Color.vitalyExcellent)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }

                // Color bar at bottom
                Capsule()
                    .fill(hasData ? Color.vitalySleep : Color.clear)
                    .frame(height: 3)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
            }
            .frame(minHeight: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.vitalyCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct WeeklyTrendChart: View {
    let data: [DayTrendData]

    var body: some View {
        if data.isEmpty {
            Text("No trend data")
                .font(.subheadline)
                .foregroundStyle(Color.vitalyTextSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart(data) { item in
                BarMark(
                    x: .value("Day", item.dayName),
                    y: .value("Score", item.score)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.vitalyPrimary, Color.vitalySecondary],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.vitalySurface)
                    AxisValueLabel()
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
        }
    }
}

struct WeekStatItem: View {
    let label: String
    let value: Double
    let unit: String
    let trend: TrendDirection

    enum TrendDirection {
        case up, down, stable

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return .vitalyExcellent
            case .down: return .vitalyHeart
            case .stable: return .vitalyTextSecondary
            }
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.vitalyTextSecondary)

            HStack(spacing: 4) {
                Text(formattedValue)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.vitalyTextPrimary)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }

            Image(systemName: trend.icon)
                .font(.system(size: 10))
                .foregroundStyle(trend.color)
        }
        .frame(maxWidth: .infinity)
    }

    private var formattedValue: String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - Activity Timeline Row
struct ActivityTimelineRow: View {
    let workout: WorkoutSummary

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(workoutColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: workoutIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(workoutColor)

                Text("\(Int(workout.duration / 60))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(workoutColor)
                    .clipShape(Capsule())
                    .offset(x: 16, y: 16)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutType)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text(formattedTime)
                    .font(.caption)
                    .foregroundStyle(Color.vitalyTextSecondary)
            }

            Spacer()
        }
        .padding(16)
    }

    private var workoutIcon: String {
        switch workout.workoutType.lowercased() {
        case "löpning", "running": return "figure.run"
        case "promenad", "walking": return "figure.walk"
        case "cykling", "cycling": return "figure.outdoor.cycle"
        case "simning", "swimming": return "figure.pool.swim"
        case "yoga": return "figure.yoga"
        case "styrketräning", "strength training": return "dumbbell.fill"
        case "hiit": return "flame.fill"
        default: return "figure.mixed.cardio"
        }
    }

    private var workoutColor: Color {
        switch workout.workoutType.lowercased() {
        case "löpning", "running": return .vitalyActivity
        case "promenad", "walking": return .vitalyExcellent
        case "cykling", "cycling": return .vitalyRecovery
        case "simning", "swimming": return .vitalySleep
        case "styrketräning", "strength training": return .vitalyHeart
        default: return .vitalyPrimary
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: workout.startTime)
    }
}

// MARK: - Day Trend Data
struct DayTrendData: Identifiable {
    let id = UUID()
    let dayName: String
    let score: Double
}

// MARK: - Preview
#Preview {
    DashboardView()
}
