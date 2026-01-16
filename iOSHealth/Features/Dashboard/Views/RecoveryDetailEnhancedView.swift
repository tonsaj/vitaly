import SwiftUI

struct RecoveryDetailEnhancedView: View {
    @Environment(\.dismiss) private var dismiss
    let recoveryScore: Double
    let sleepData: SleepData?
    let heartData: HeartData?
    let hrvHistory: [Double]

    @State private var animateRing = false
    @State private var aiInsight: String?
    @State private var isLoadingAI = false
    @State private var hasLoadedAI = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.vitalyBackground,
                    Color(red: 0.06, green: 0.08, blue: 0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Large Ring Gauge
                    largeRecoveryRing

                    // AI Insight Card
                    aiInsightCard

                    // Recovery Breakdown
                    recoveryBreakdown

                    // HRV Trend
                    hrvTrendCard

                    // Recovery Tips
                    recoveryTipsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Recovery")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)
            }

            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.vitalyCardBackground)
                            .frame(width: 34, height: 34)

                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.vitalyTextPrimary)
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Info action
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.vitalyCardBackground)
                            .frame(width: 34, height: 34)

                        Image(systemName: "info")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.vitalyTextPrimary)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).delay(0.2)) {
                animateRing = true
            }
        }
        .task {
            await loadAIInsight()
        }
    }

    // MARK: - AI Insight Card
    private var aiInsightCard: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.vitalyRecovery)

                    Text("AI ÅTERHÄMTNINGSANALYS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)

                    Spacer()

                    if isLoadingAI {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .vitalyRecovery))
                            .scaleEffect(0.7)
                    }
                }

                if isLoadingAI {
                    Text("Analyserar din återhämtning...")
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
        if recoveryScore >= 80 {
            return "Din återhämtning är utmärkt! Du är redo för en intensiv träningsdag."
        } else if recoveryScore >= 60 {
            return "God återhämtning. Du kan träna som vanligt, men lyssna på kroppen."
        } else if recoveryScore >= 40 {
            return "Måttlig återhämtning. Överväg att ta det lite lugnare idag."
        } else {
            return "Din kropp behöver mer vila. Prioritera sömn och återhämtning."
        }
    }

    @MainActor
    private func loadAIInsight() async {
        guard !hasLoadedAI else { return }
        hasLoadedAI = true
        isLoadingAI = true

        do {
            aiInsight = try await GeminiService.shared.generateMetricInsight(
                metric: .heart,
                todayValue: heartData?.hrv ?? recoveryScore,
                yesterdayValue: hrvHistory.count > 1 ? hrvHistory[hrvHistory.count - 2] : nil,
                weeklyAverage: hrvHistory.isEmpty ? nil : hrvHistory.reduce(0, +) / Double(hrvHistory.count),
                goal: 50, // Gott HRV-mål
                unit: "ms"
            )
        } catch {
            aiInsight = nil
        }
        isLoadingAI = false
    }

    // MARK: - Large Recovery Ring
    private var largeRecoveryRing: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.vitalyExcellent.opacity(0.15), lineWidth: 24)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animateRing ? min(recoveryScore / 100, 1.0) : 0)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.vitalyExcellent.opacity(0.6),
                                Color.vitalyExcellent,
                                Color.vitalyExcellent,
                                Color.vitalyExcellent.opacity(0.8)
                            ],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.vitalyExcellent.opacity(0.4), radius: 8, x: 0, y: 0)

                // Center content
                VStack(spacing: 8) {
                    Text("\(Int(recoveryScore))")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Text("Recovery")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
            .frame(width: 240, height: 240)

            // Status label
            HStack(spacing: 8) {
                Circle()
                    .fill(recoveryColor)
                    .frame(width: 8, height: 8)

                Text(recoveryLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(recoveryColor)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(recoveryColor.opacity(0.15))
            )
        }
        .padding(.vertical, 20)
    }

    // MARK: - Recovery Breakdown
    private var recoveryBreakdown: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 20) {
                Text("UPPDELNING")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .tracking(1.2)

                // Sleep Quality
                RecoveryFactorRow(
                    icon: "bed.double.fill",
                    label: "Sömnkvalitet",
                    value: sleepQualityScore,
                    maxValue: 100,
                    color: Color.vitalySleep
                )

                Divider()
                    .background(Color.vitalySurface)

                // HRV
                RecoveryFactorRow(
                    icon: "waveform.path.ecg",
                    label: "Hjärtvariabilitet (HRV)",
                    value: heartData?.hrv ?? 0,
                    maxValue: 100,
                    color: Color.vitalyRecovery
                )

                Divider()
                    .background(Color.vitalySurface)

                // Resting Heart Rate
                RecoveryFactorRow(
                    icon: "heart.fill",
                    label: "Vilopuls",
                    value: restingHRScore,
                    maxValue: 100,
                    color: Color.vitalyHeart
                )
            }
            .padding(20)
        }
    }

    // MARK: - HRV Trend Card
    private var hrvTrendCard: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("HRV TREND")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)

                    Spacer()

                    Text("7 dagar")
                        .font(.caption)
                        .foregroundStyle(Color.vitalyTextSecondary)
                }

                // Mini line chart
                MiniLineChart(
                    data: hrvHistory.isEmpty ? [heartData?.hrv ?? 50] : hrvHistory,
                    color: Color.vitalyRecovery
                )
                .frame(height: 100)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nuvarande")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)

                        Text(String(format: "%.0f ms", heartData?.hrv ?? 0))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.vitalyTextPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Genomsnitt")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)

                        Text(hrvAverageText)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.vitalyTextPrimary)
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Recovery Tips Card
    private var recoveryTipsCard: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.vitalyRecovery)

                    Text("ÅTERHÄMTNINGSTIPS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                VStack(alignment: .leading, spacing: 14) {
                    TipRow(
                        icon: "moon.zzz.fill",
                        text: "Sträva efter 7-9 timmars kvalitetssömn varje natt"
                    )

                    TipRow(
                        icon: "drop.fill",
                        text: "Håll dig väl hydrerad - drick minst 2 liter vatten dagligen"
                    )

                    TipRow(
                        icon: "figure.walk",
                        text: "Inkludera aktiv återhämtning som lätt promenad eller stretching"
                    )

                    TipRow(
                        icon: "leaf.fill",
                        text: "Ät näringsrik mat med fokus på protein och antioxidanter"
                    )
                }
            }
            .padding(20)
        }
    }

    // MARK: - Computed Properties
    private var recoveryColor: Color {
        switch recoveryScore {
        case 0..<40: return Color.vitalyPoor
        case 40..<60: return Color.vitalyFair
        case 60..<80: return Color.vitalyGood
        default: return Color.vitalyExcellent
        }
    }

    private var recoveryLabel: String {
        switch recoveryScore {
        case 0..<40: return "Dålig återhämtning"
        case 40..<60: return "Acceptabel återhämtning"
        case 60..<80: return "Bra återhämtning"
        default: return "Utmärkt återhämtning"
        }
    }

    private var sleepQualityScore: Double {
        guard let sleep = sleepData else { return 0 }
        // Calculate score based on total hours (8h = 100)
        return min(100, (sleep.totalHours / 8.0) * 100)
    }

    private var restingHRScore: Double {
        guard let rhr = heartData?.restingHeartRate else { return 0 }
        // Lower RHR is better (60 = 100%, 40 = 100%, 80+ = lower score)
        if rhr <= 60 {
            return 100
        } else if rhr <= 70 {
            return 90 - (rhr - 60)
        } else {
            return max(50, 80 - (rhr - 70) * 2)
        }
    }

    private var hrvAverageText: String {
        let validHRV = hrvHistory.filter { $0 > 0 }
        guard !validHRV.isEmpty else { return "-- ms" }
        let avg = validHRV.reduce(0, +) / Double(validHRV.count)
        return String(format: "%.0f ms", avg)
    }
}

// MARK: - Recovery Factor Row
struct RecoveryFactorRow: View {
    let icon: String
    let label: String
    let value: Double
    let maxValue: Double
    let color: Color

    private var percentage: Double {
        min(value / maxValue, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(color)

                    Text(label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.vitalyTextPrimary)
                }

                Spacer()

                Text(String(format: "%.0f%%", percentage * 100))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.vitalyTextPrimary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.vitalySurface)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * percentage, height: 8)
                        .animation(.easeOut(duration: 1.0).delay(0.3), value: percentage)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Tip Row
struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.vitalyRecovery.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.vitalyRecovery)
            }

            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.vitalyTextPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Mini Line Chart
struct MiniLineChart: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.max() ?? 1
            let minValue = data.min() ?? 0
            let range = maxValue - minValue

            ZStack {
                // Grid lines
                VStack(spacing: 0) {
                    ForEach(0..<3) { _ in
                        Spacer()
                        Rectangle()
                            .fill(Color.vitalySurface.opacity(0.5))
                            .frame(height: 1)
                    }
                }

                // Line chart
                Path { path in
                    let stepX = geometry.size.width / CGFloat(data.count - 1)

                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
                        let y = geometry.size.height - (CGFloat(normalizedValue) * geometry.size.height)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                // Fill area under line
                Path { path in
                    let stepX = geometry.size.width / CGFloat(data.count - 1)

                    path.move(to: CGPoint(x: 0, y: geometry.size.height))

                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
                        let y = geometry.size.height - (CGFloat(normalizedValue) * geometry.size.height)

                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Data points
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    let x = (CGFloat(index) / CGFloat(data.count - 1)) * geometry.size.width
                    let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
                    let y = geometry.size.height - (CGFloat(normalizedValue) * geometry.size.height)

                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecoveryDetailEnhancedView(
            recoveryScore: 85,
            sleepData: SleepData(
                id: "1",
                date: Date(),
                totalDuration: 7.5 * 3600,
                deepSleep: 1.8 * 3600,
                remSleep: 2.1 * 3600,
                lightSleep: 3.6 * 3600,
                awake: 0.3 * 3600,
                bedtime: Date().addingTimeInterval(-8 * 3600),
                wakeTime: Date()
            ),
            heartData: HeartData(
                id: "1",
                date: Date(),
                restingHeartRate: 58,
                averageHeartRate: 72,
                maxHeartRate: 145,
                minHeartRate: 52,
                hrv: 56,
                heartRateZones: []
            ),
            hrvHistory: [45, 52, 48, 55, 58, 54, 56]
        )
    }
    .preferredColorScheme(.dark)
}
