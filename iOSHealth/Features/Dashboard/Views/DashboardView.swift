import SwiftUI
import Charts

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var selectedMetric: DashboardMetric?

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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection

                        if viewModel.isLoading {
                            loadingView
                        } else if let error = viewModel.error {
                            errorView(error)
                        } else if viewModel.hasData {
                            VStack(spacing: 20) {
                                // Dagens sammanfattning med jämförelse
                                dailySummaryCard

                                // Hälsometriker (6 kort med navigation)
                                healthMetricsSection

                                // 7-dagars trend
                                weeklyTrendSection

                                // Aktivitetstidslinje
                                activityTimelineSection
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            .padding(.bottom, 100)
                        } else {
                            emptyStateView
                        }
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    SunburstIcon(rayCount: 8, color: .vitalyPrimary)
                        .frame(width: 28, height: 28)
                }
            }
            .task {
                await viewModel.loadTodayData()
            }
            .sheet(item: $selectedMetric) { metric in
                MetricDetailSheet(
                    metric: metric,
                    currentValue: currentValue(for: metric),
                    yesterdayValue: yesterdayValue(for: metric),
                    weekData: weekData(for: metric)
                )
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.todayDate)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.vitalyTextPrimary)

                if viewModel.isDemoMode {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.vitalyPrimary)
                            .frame(width: 6, height: 6)
                        Text("DEMO-LÄGE")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.vitalyPrimary)
                    }
                }
            }

            Spacer()

            Circle()
                .fill(LinearGradient.vitalyGradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Text("V")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                )
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Dagens Sammanfattning
    private var dailySummaryCard: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("DAGENS LÄGE")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)

                    Spacer()

                    // Status indikator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(statusText)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(statusColor)
                    }
                }

                Text(summaryMessage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.vitalyTextPrimary)
                    .lineSpacing(4)

                // Jämförelse med igår
                Divider()
                    .background(Color.vitalySurface)

                HStack(spacing: 20) {
                    ComparisonItem(
                        label: "Sömn",
                        todayValue: viewModel.sleepData?.formattedDuration ?? "-",
                        change: sleepChange,
                        icon: "bed.double.fill"
                    )

                    ComparisonItem(
                        label: "Steg",
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

    // MARK: - Hälsometriker (6 kort)
    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hälsometriker")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.vitalyTextPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                // Sömn
                TappableMetricCard(
                    icon: "bed.double.fill",
                    label: "Sömn",
                    value: viewModel.sleepData?.formattedDuration ?? "-",
                    unit: "",
                    hasData: viewModel.sleepData != nil,
                    color: .vitalySleep
                ) {
                    selectedMetric = .sleep
                }

                // Steg
                TappableMetricCard(
                    icon: "figure.walk",
                    label: "Steg",
                    value: "\(viewModel.activityData?.steps ?? 0)",
                    unit: "",
                    hasData: viewModel.activityData != nil,
                    color: .vitalyActivity
                ) {
                    selectedMetric = .steps
                }

                // RR (Andningsfrekvens)
                TappableMetricCard(
                    icon: "lungs.fill",
                    label: "RR",
                    value: "13.1",
                    unit: "rpm",
                    hasData: true,
                    color: .vitalySleep
                ) {
                    selectedMetric = .respiratoryRate
                }

                // RHR (Vilopuls)
                TappableMetricCard(
                    icon: "heart.fill",
                    label: "RHR",
                    value: String(format: "%.0f", viewModel.heartData?.restingHeartRate ?? 0),
                    unit: "bpm",
                    hasData: viewModel.heartData?.restingHeartRate != nil,
                    color: .vitalyHeart
                ) {
                    selectedMetric = .restingHeartRate
                }

                // HRV
                TappableMetricCard(
                    icon: "waveform.path.ecg",
                    label: "HRV",
                    value: String(format: "%.0f", viewModel.heartData?.hrv ?? 0),
                    unit: "ms",
                    hasData: viewModel.heartData?.hrv != nil,
                    color: .vitalyRecovery
                ) {
                    selectedMetric = .hrv
                }

                // SpO2
                TappableMetricCard(
                    icon: "drop.fill",
                    label: "SpO2",
                    value: "98",
                    unit: "%",
                    hasData: true,
                    color: .vitalyPrimary
                ) {
                    selectedMetric = .oxygenSaturation
                }
            }
        }
    }

    // MARK: - 7-dagars Trend
    private var weeklyTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Senaste 7 dagarna")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Spacer()

                Text("Översikt")
                    .font(.subheadline)
                    .foregroundStyle(Color.vitalyTextSecondary)
            }

            VitalyCard {
                VStack(spacing: 16) {
                    // Mini-trendgraf
                    WeeklyTrendChart(data: viewModel.weeklyTrendData)
                        .frame(height: 120)

                    // Veckostatistik
                    HStack(spacing: 0) {
                        WeekStatItem(
                            label: "Snitt sömn",
                            value: viewModel.averageSleepHours,
                            unit: "h",
                            trend: .up
                        )

                        Divider()
                            .frame(height: 40)
                            .background(Color.vitalySurface)

                        WeekStatItem(
                            label: "Snitt steg",
                            value: Double(viewModel.averageSteps),
                            unit: "",
                            trend: .stable
                        )

                        Divider()
                            .frame(height: 40)
                            .background(Color.vitalySurface)

                        WeekStatItem(
                            label: "Snitt HRV",
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

    // MARK: - Aktivitetstidslinje
    private var activityTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aktiviteter idag")
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
                            Text("Ingen aktivitet än")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.vitalyTextPrimary)

                            Text("Dina träningspass visas här")
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

            Text("Laddar hälsodata...")
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

                Text("Ingen data än")
                    .font(.headline)
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text("Anslut till HealthKit för att börja spåra din hälsa.")
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

                Text("Kunde inte ladda data")
                    .font(.headline)
                    .foregroundStyle(Color.vitalyTextPrimary)

                HStack(spacing: 12) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Text("Försök igen")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.vitalyGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        viewModel.loadDemoData()
                    } label: {
                        Text("Visa demo")
                            .font(.headline)
                            .foregroundStyle(Color.vitalyPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.vitalyPrimary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
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
        if score >= 80 { return "Utmärkt" }
        if score >= 60 { return "Bra" }
        return "Vila rekommenderas"
    }

    private var summaryMessage: String {
        guard viewModel.hasData else { return "Laddar..." }

        let sleep = viewModel.sleepData
        let hrv = viewModel.heartData?.hrv ?? 0

        if let s = sleep, s.totalHours >= 7 && hrv >= 50 {
            return "Du har sovit bra och din kropp visar god återhämtning. En perfekt dag för aktivitet!"
        } else if let s = sleep, s.totalHours < 6 {
            return "Din sömn var kortare än rekommenderat. Prioritera vila och undvik intensiv träning idag."
        } else {
            return "Din kropp återhämtar sig. Lyssna på hur du känner dig och anpassa dagens aktivitet därefter."
        }
    }

    private var sleepChange: Double {
        // Simulerad förändring jämfört med igår
        return 0.5
    }

    private var stepsChange: Double {
        return -1200
    }

    private var hrvChange: Double {
        return 3
    }

    // Helper för MetricDetailSheet
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
        case .sleep: return 7.0
        case .steps: return 9500
        case .respiratoryRate: return 12.8
        case .restingHeartRate: return 60
        case .hrv: return 52
        case .oxygenSaturation: return 97
        }
    }

    private func weekData(for metric: DashboardMetric) -> [Double] {
        // Simulerad veckodata
        switch metric {
        case .sleep: return [7.2, 6.5, 7.8, 6.9, 7.5, 8.0, 7.3]
        case .steps: return [8500, 10200, 7800, 9100, 8900, 11000, 8500]
        case .respiratoryRate: return [13.0, 12.8, 13.2, 13.1, 12.9, 13.0, 13.1]
        case .restingHeartRate: return [58, 60, 57, 59, 58, 56, 58]
        case .hrv: return [52, 48, 55, 50, 53, 58, 55]
        case .oxygenSaturation: return [97, 98, 98, 97, 98, 99, 98]
        }
    }
}

// MARK: - Dashboard Metric Type
enum DashboardMetric: String, Identifiable {
    case sleep, steps, respiratoryRate, restingHeartRate, hrv, oxygenSaturation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sleep: return "Sömn"
        case .steps: return "Steg"
        case .respiratoryRate: return "Andningsfrekvens"
        case .restingHeartRate: return "Vilopuls"
        case .hrv: return "Hjärtvariabilitet"
        case .oxygenSaturation: return "Syremättnad"
        }
    }

    var unit: String {
        switch self {
        case .sleep: return "timmar"
        case .steps: return "steg"
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.vitalyTextPrimary)

                            if !unit.isEmpty {
                                Text(unit)
                                    .font(.caption)
                                    .foregroundStyle(Color.vitalyTextSecondary)
                            }
                        }
                    } else {
                        Text("Ingen data")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.vitalyTextSecondary.opacity(0.6))
                    }
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
        .buttonStyle(.plain)
    }
}

struct WeeklyTrendChart: View {
    let data: [DayTrendData]

    var body: some View {
        if data.isEmpty {
            Text("Ingen trenddata")
                .font(.subheadline)
                .foregroundStyle(Color.vitalyTextSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart(data) { item in
                BarMark(
                    x: .value("Dag", item.dayName),
                    y: .value("Poäng", item.score)
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

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
        .padding(16)
    }

    private var workoutIcon: String {
        switch workout.workoutType.lowercased() {
        case "löpning": return "figure.run"
        case "promenad": return "figure.walk"
        case "cykling": return "figure.outdoor.cycle"
        case "simning": return "figure.pool.swim"
        case "yoga": return "figure.yoga"
        case "styrketräning": return "dumbbell.fill"
        case "hiit": return "flame.fill"
        default: return "figure.mixed.cardio"
        }
    }

    private var workoutColor: Color {
        switch workout.workoutType.lowercased() {
        case "löpning": return .vitalyActivity
        case "promenad": return .vitalyExcellent
        case "cykling": return .vitalyRecovery
        case "simning": return .vitalySleep
        case "styrketräning": return .vitalyHeart
        default: return .vitalyPrimary
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "sv_SE")
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
