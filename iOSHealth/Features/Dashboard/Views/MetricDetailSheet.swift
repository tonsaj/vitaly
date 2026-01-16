import SwiftUI
import Charts

struct MetricDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let metric: DashboardMetric
    let currentValue: Double
    let yesterdayValue: Double
    let weekData: [Double]
    var goal: Double? = nil
    // Sleep-specific data for detailed AI analysis
    var sleepData: SleepData? = nil
    var yesterdaySleepData: SleepData? = nil
    // Weekly sleep data for sleep stage trends
    var weeklySleepData: [SleepData?] = []

    @State private var animateChart = false
    @State private var aiInsight: String?
    @State private var isLoadingAI = false
    @State private var hasLoadedAI = false
    @State private var showInfoCard = false

    private var change: Double {
        currentValue - yesterdayValue
    }

    private var changePercent: Double {
        guard yesterdayValue != 0 else { return 0 }
        return ((currentValue - yesterdayValue) / yesterdayValue) * 100
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Nuvarande värde (kompakt)
                        currentValueCard

                        // Info Card (visas när ? trycks)
                        if showInfoCard {
                            infoCard
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity
                                ))
                        }

                        // AI Insight
                        aiInsightCard

                        // Today's sleep stages breakdown (only for sleep)
                        if metric == .sleep, let sleep = sleepData {
                            todaySleepStagesCard(for: sleep)
                        }

                        // Jämförelse med igår
                        comparisonCard

                        // 7-dagars trend
                        trendChartCard

                        // Sleep stages trend (only for sleep)
                        if metric == .sleep && !weeklySleepData.isEmpty {
                            sleepStagesTrendCard
                        }

                        // Sleep recommendations (only for sleep)
                        if metric == .sleep, let sleep = sleepData {
                            sleepRecommendationsCard(for: sleep)
                        }

                        // Statistik
                        statisticsCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showInfoCard.toggle()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(showInfoCard ? metric.color.opacity(0.2) : Color.vitalyCardBackground)
                                .frame(width: 34, height: 34)

                            Text("?")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(showInfoCard ? metric.color : Color.vitalyTextSecondary)
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(metric.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.vitalyTextPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.vitalyCardBackground)
                                .frame(width: 34, height: 34)

                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.vitalyTextPrimary)
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animateChart = true
            }
        }
        .task {
            await loadAIInsight()
        }
    }

    // MARK: - Info Card (Vad är detta?)
    private var infoCard: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.vitalyTextSecondary.opacity(0.15))
                            .frame(width: 24, height: 24)

                        Text("?")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }

                    Text("WHAT IS THIS?")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                Text(metricExplanation)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.vitalyTextPrimary)
                    .lineSpacing(5)
            }
            .padding(18)
        }
    }

    private var metricExplanation: String {
        switch metric {
        case .sleep:
            return "Sleep measures how long you slept during the night. 7-9 hours is recommended for adults. Good sleep is crucial for recovery, immune function and cognitive performance."

        case .steps:
            return "Steps counts how many steps you've taken during the day. 10,000 steps/day is a common goal. Regular movement improves fitness, metabolism and mental health."

        case .respiratoryRate:
            return "Respiratory Rate (RR) measures breaths per minute at rest. Normal rate is 12-20 rpm. Elevated respiratory rate can indicate stress, illness or poor fitness."

        case .restingHeartRate:
            return "Resting Heart Rate (RHR) is your pulse when fully relaxed. Normal resting heart rate is 60-100 bpm, but well-trained individuals can have 40-60 bpm. Lower resting heart rate often indicates better heart health."

        case .hrv:
            return "Heart Rate Variability (HRV) measures the variation between heartbeats in milliseconds. Higher HRV indicates good recovery and flexibility in the nervous system. Stress and fatigue lower HRV."

        case .oxygenSaturation:
            return "Oxygen Saturation (SpO2) shows how well the blood transports oxygen. Normal value is 95-100%. Values below 95% can indicate breathing problems and should be evaluated by a doctor."
        }
    }

    // MARK: - AI Insight Card
    private var aiInsightCard: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(metric.color)

                    Text("AI ANALYSIS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)

                    Spacer()

                    if isLoadingAI {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: metric.color))
                            .scaleEffect(0.7)
                    }
                }

                if isLoadingAI {
                    Text("Analyzing \(metric.title.lowercased())...")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.vitalyTextSecondary)
                } else if let insight = aiInsight {
                    Text(insight)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .lineSpacing(5)
                } else {
                    Text(fallbackInsight)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .lineSpacing(5)
                }
            }
            .padding(18)
        }
    }

    private var fallbackInsight: String {
        let weekAvg = weekData.reduce(0, +) / Double(weekData.count)
        if currentValue >= weekAvg {
            return "Well done! Your value today is above the weekly average."
        } else {
            return "Your value is slightly below average. Focus on \(metric.title.lowercased()) going forward."
        }
    }

    @MainActor
    private func loadAIInsight() async {
        guard !hasLoadedAI else { return }
        hasLoadedAI = true
        isLoadingAI = true

        do {
            let weekAvg = weekData.reduce(0, +) / Double(weekData.count)

            // Use detailed sleep analysis if we have sleep data
            if metric == .sleep, let sleep = sleepData {
                aiInsight = try await GeminiService.shared.generateSleepInsight(
                    sleepData: sleep,
                    yesterdaySleep: yesterdaySleepData,
                    weeklyAverageSleep: weekAvg,
                    goal: goal ?? 8.0
                )
            } else {
                let metricType: MetricType = {
                    switch metric {
                    case .sleep: return .sleep
                    case .steps, .respiratoryRate: return .activity
                    case .restingHeartRate, .hrv, .oxygenSaturation: return .heart
                    }
                }()

                aiInsight = try await GeminiService.shared.generateMetricInsight(
                    metric: metricType,
                    todayValue: currentValue,
                    yesterdayValue: yesterdayValue,
                    weeklyAverage: weekAvg,
                    goal: goal,
                    unit: metric.unit
                )
            }
        } catch {
            aiInsight = nil
        }
        isLoadingAI = false
    }

    // MARK: - Nuvarande Värde (kompakt)
    private var currentValueCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(metric.color.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: metric.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(metric.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .tracking(1)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formattedValue(currentValue))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Text(metric.unit)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }

            Spacer()

            // Mini trend indicator
            VStack(alignment: .trailing, spacing: 2) {
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(changeColor)

                Text(changeText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(changeColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }

    // MARK: - Jämförelse med igår
    private var comparisonCard: some View {
        VitalyCard {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("COMPARED TO YESTERDAY")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)

                    HStack(spacing: 8) {
                        Image(systemName: change >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(changeColor)

                        Text(changeText)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(changeColor)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Yesterday")
                        .font(.caption)
                        .foregroundStyle(Color.vitalyTextSecondary)

                    Text("\(formattedValue(yesterdayValue)) \(metric.unit)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.vitalyTextPrimary)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Trend Chart
    private var trendChartCard: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("LAST 7 DAYS")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .tracking(1.2)

                Chart {
                    ForEach(Array(weekData.enumerated()), id: \.offset) { index, value in
                        BarMark(
                            x: .value("Dag", dayName(for: index)),
                            y: .value("Värde", animateChart ? value : 0)
                        )
                        .foregroundStyle(
                            index == weekData.count - 1 ?
                            metric.color :
                            metric.color.opacity(0.5)
                        )
                        .cornerRadius(4)
                    }
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
                .frame(height: 180)
            }
            .padding(20)
        }
    }

    // MARK: - Today's Sleep Stages Breakdown
    @ViewBuilder
    private func todaySleepStagesCard(for sleep: SleepData) -> some View {
        let deepMinutes = Int(sleep.deepSleep / 60)
        let remMinutes = Int(sleep.remSleep / 60)
        let lightMinutes = Int(sleep.lightSleep / 60)
        let awakeMinutes = Int(sleep.awake / 60)

        let deepPercent = sleep.totalDuration > 0 ? Int((sleep.deepSleep / sleep.totalDuration) * 100) : 0
        let remPercent = sleep.totalDuration > 0 ? Int((sleep.remSleep / sleep.totalDuration) * 100) : 0
        let lightPercent = sleep.totalDuration > 0 ? Int((sleep.lightSleep / sleep.totalDuration) * 100) : 0
        let awakePercent = sleep.totalDuration > 0 ? Int((sleep.awake / sleep.totalDuration) * 100) : 0

        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("TONIGHT'S SLEEP STAGES")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .tracking(1.2)

                // Visual breakdown bar - proportional widths
                GeometryReader { geometry in
                    let totalPercent = max(deepPercent + remPercent + lightPercent + awakePercent, 1)
                    let spacing: CGFloat = 6 // 3 gaps * 2
                    let availableWidth = geometry.size.width - spacing

                    HStack(spacing: 2) {
                        // Deep
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.4, green: 0.3, blue: 0.7))
                            .frame(width: availableWidth * CGFloat(deepPercent) / CGFloat(totalPercent))

                        // REM
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.vitalySleep)
                            .frame(width: availableWidth * CGFloat(remPercent) / CGFloat(totalPercent))

                        // Light
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.vitalySleep.opacity(0.4))
                            .frame(width: availableWidth * CGFloat(lightPercent) / CGFloat(totalPercent))

                        // Awake
                        if awakePercent > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.vitalyTextSecondary.opacity(0.3))
                                .frame(width: availableWidth * CGFloat(awakePercent) / CGFloat(totalPercent))
                        }
                    }
                }
                .frame(height: 12)

                // Detailed stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    // Deep Sleep
                    SleepStageItem(
                        icon: "bed.double.fill",
                        label: "Deep Sleep",
                        value: formatMinutes(deepMinutes),
                        percent: "\(deepPercent)%",
                        color: Color(red: 0.4, green: 0.3, blue: 0.7),
                        isGood: deepPercent >= 15,
                        goalText: "Goal: ≥15%"
                    )

                    // REM Sleep
                    SleepStageItem(
                        icon: "moon.stars.fill",
                        label: "REM Sleep",
                        value: formatMinutes(remMinutes),
                        percent: "\(remPercent)%",
                        color: Color.vitalySleep,
                        isGood: remPercent >= 20,
                        goalText: "Goal: ≥20%"
                    )

                    // Light Sleep
                    SleepStageItem(
                        icon: "moon.fill",
                        label: "Light Sleep",
                        value: formatMinutes(lightMinutes),
                        percent: "\(lightPercent)%",
                        color: Color.vitalySleep.opacity(0.6),
                        isGood: nil,
                        goalText: nil
                    )

                    // Awake
                    SleepStageItem(
                        icon: "eye.fill",
                        label: "Awake",
                        value: formatMinutes(awakeMinutes),
                        percent: "\(awakePercent)%",
                        color: Color.vitalyTextSecondary,
                        isGood: awakePercent <= 10,
                        goalText: "Goal: ≤10%"
                    )
                }
            }
            .padding(20)
        }
    }

    // MARK: - Sleep Stages Trend (REM & Deep Sleep)
    private var sleepStagesTrendCard: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("SLEEP STAGES (7 DAYS)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .tracking(1.2)

                // Legend
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(red: 0.4, green: 0.3, blue: 0.7))
                            .frame(width: 8, height: 8)
                        Text("Deep")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.vitalySleep)
                            .frame(width: 8, height: 8)
                        Text("REM")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }

                // Stacked bar chart for sleep stages
                Chart {
                    ForEach(Array(weeklySleepData.enumerated()), id: \.offset) { index, sleep in
                        if let sleep = sleep {
                            // Deep sleep
                            BarMark(
                                x: .value("Day", dayName(for: index)),
                                y: .value("Minutes", Int(sleep.deepSleep / 60))
                            )
                            .foregroundStyle(Color(red: 0.4, green: 0.3, blue: 0.7))
                            .cornerRadius(2)

                            // REM sleep (stacked)
                            BarMark(
                                x: .value("Day", dayName(for: index)),
                                y: .value("Minutes", Int(sleep.remSleep / 60))
                            )
                            .foregroundStyle(Color.vitalySleep)
                            .cornerRadius(2)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.vitalySurface)
                        AxisValueLabel {
                            if let mins = value.as(Int.self) {
                                Text("\(mins)m")
                                    .font(.caption2)
                            }
                        }
                        .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }
                .frame(height: 150)

                // Averages
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("Avg Deep")
                            .font(.caption2)
                            .foregroundStyle(Color.vitalyTextSecondary)
                        Text(formatMinutes(averageDeepSleep))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.4, green: 0.3, blue: 0.7))
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 40)
                        .background(Color.vitalySurface)

                    VStack(spacing: 4) {
                        Text("Avg REM")
                            .font(.caption2)
                            .foregroundStyle(Color.vitalyTextSecondary)
                        Text(formatMinutes(averageRemSleep))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.vitalySleep)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
    }

    private var averageDeepSleep: Int {
        let validSleep = weeklySleepData.compactMap { $0 }
        guard !validSleep.isEmpty else { return 0 }
        let total = validSleep.reduce(0) { $0 + $1.deepSleep }
        return Int(total / Double(validSleep.count) / 60)
    }

    private var averageRemSleep: Int {
        let validSleep = weeklySleepData.compactMap { $0 }
        guard !validSleep.isEmpty else { return 0 }
        let total = validSleep.reduce(0) { $0 + $1.remSleep }
        return Int(total / Double(validSleep.count) / 60)
    }

    // MARK: - Sleep Recommendations
    @ViewBuilder
    private func sleepRecommendationsCard(for sleep: SleepData) -> some View {
        let deepPercent = sleep.totalDuration > 0 ? (sleep.deepSleep / sleep.totalDuration) * 100 : 0
        let remPercent = sleep.totalDuration > 0 ? (sleep.remSleep / sleep.totalDuration) * 100 : 0

        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.vitalySleep)

                    Text("PERSONALIZED TIPS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                VStack(alignment: .leading, spacing: 12) {
                    // Deep sleep recommendation
                    if deepPercent < 15 {
                        SleepTipItem(
                            icon: "bed.double.fill",
                            title: "Increase Deep Sleep",
                            tip: "Try exercising earlier in the day and keep your bedroom cool (16-19°C) for better deep sleep.",
                            color: Color(red: 0.4, green: 0.3, blue: 0.7)
                        )
                    } else {
                        SleepTipItem(
                            icon: "checkmark.circle.fill",
                            title: "Deep Sleep: Good!",
                            tip: "Your deep sleep is at \(Int(deepPercent))%, which is optimal for physical recovery.",
                            color: .vitalyExcellent
                        )
                    }

                    // REM sleep recommendation
                    if remPercent < 20 {
                        SleepTipItem(
                            icon: "moon.stars.fill",
                            title: "Increase REM Sleep",
                            tip: "Maintain a consistent sleep schedule and avoid alcohol before bed to improve REM sleep.",
                            color: Color.vitalySleep
                        )
                    } else {
                        SleepTipItem(
                            icon: "checkmark.circle.fill",
                            title: "REM Sleep: Good!",
                            tip: "Your REM sleep is at \(Int(remPercent))%, supporting memory and mental recovery.",
                            color: .vitalyExcellent
                        )
                    }

                    // Total sleep recommendation
                    if sleep.totalHours < 7 {
                        SleepTipItem(
                            icon: "clock.fill",
                            title: "Sleep Duration",
                            tip: "Try to get 7-9 hours of sleep. Consider going to bed 30 minutes earlier.",
                            color: .vitalyFair
                        )
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Helpers
    private func formatMinutes(_ minutes: Int) -> String {
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

    // MARK: - Statistik
    private var statisticsCard: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("STATISTICS (7 DAYS)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .tracking(1.2)

                HStack(spacing: 0) {
                    StatBox(
                        label: "Avg",
                        value: formattedValue(weekData.reduce(0, +) / Double(weekData.count)),
                        unit: metric.unit,
                        color: metric.color
                    )

                    Divider()
                        .frame(height: 50)
                        .background(Color.vitalySurface)

                    StatBox(
                        label: "High",
                        value: formattedValue(weekData.max() ?? 0),
                        unit: metric.unit,
                        color: .vitalyExcellent
                    )

                    Divider()
                        .frame(height: 50)
                        .background(Color.vitalySurface)

                    StatBox(
                        label: "Low",
                        value: formattedValue(weekData.min() ?? 0),
                        unit: metric.unit,
                        color: .vitalyHeart
                    )
                }
            }
            .padding(20)
        }
    }

    // MARK: - Helpers
    private var changeColor: Color {
        // För vissa metriker är högre bättre, för andra är lägre bättre
        switch metric {
        case .restingHeartRate:
            return change <= 0 ? .vitalyExcellent : .vitalyHeart
        default:
            return change >= 0 ? .vitalyExcellent : .vitalyHeart
        }
    }

    private var changeText: String {
        let absChange = abs(change)
        let sign = change >= 0 ? "+" : "-"

        if metric == .steps {
            return "\(sign)\(Int(absChange))"
        }
        return "\(sign)\(String(format: "%.1f", absChange))"
    }

    private func formattedValue(_ value: Double) -> String {
        switch metric {
        case .steps:
            if value >= 1000 {
                return String(format: "%.1fk", value / 1000)
            }
            return "\(Int(value))"
        case .sleep:
            let hours = Int(value)
            let minutes = Int((value - Double(hours)) * 60)
            return "\(hours)h \(minutes)m"
        default:
            return String(format: "%.1f", value)
        }
    }

    private func dayName(for index: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        // Justera för svensk vecka (måndag = 1)
        let adjustedToday = today == 1 ? 6 : today - 2
        let dayIndex = (adjustedToday - (weekData.count - 1 - index) + 7) % 7
        return days[dayIndex]
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.vitalyTextSecondary)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text(unit)
                .font(.caption)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sleep Stage Item (for today's breakdown)
struct SleepStageItem: View {
    let icon: String
    let label: String
    let value: String
    let percent: String
    let color: Color
    let isGood: Bool?
    let goalText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 28, height: 28)

                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.vitalyTextSecondary)

                    HStack(spacing: 4) {
                        Text(value)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.vitalyTextPrimary)

                        if let isGood = isGood {
                            Image(systemName: isGood ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(isGood ? Color.vitalyExcellent : Color.vitalyFair)
                        }
                    }
                }

                Spacer()
            }

            HStack {
                Text(percent)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)

                if let goalText = goalText {
                    Spacer()
                    Text(goalText)
                        .font(.caption2)
                        .foregroundStyle(Color.vitalyTextSecondary.opacity(0.7))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.vitalySurface.opacity(0.5))
        )
    }
}

// MARK: - Sleep Tip Item
struct SleepTipItem: View {
    let icon: String
    let title: String
    let tip: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text(tip)
                    .font(.caption)
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .lineSpacing(2)
            }
        }
    }
}

#Preview {
    MetricDetailSheet(
        metric: .hrv,
        currentValue: 55,
        yesterdayValue: 52,
        weekData: [52, 48, 55, 50, 53, 58, 55]
    )
    .preferredColorScheme(.dark)
}
