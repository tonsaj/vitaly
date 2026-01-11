import SwiftUI

struct SleepDetailEnhancedView: View {
    @Environment(\.dismiss) private var dismiss
    let sleepData: SleepData?
    @State private var animateChart = false

    private var sleepPercentage: Double {
        guard let sleep = sleepData else { return 0 }
        return min(100, (sleep.totalHours / 8.0) * 100)
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.vitalyBackground,
                    Color(red: 0.06, green: 0.05, blue: 0.09)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Large Ring Gauge
                    largeSleepRing

                    // Sleep Times Card
                    sleepTimesCard

                    // Sleep Stages Breakdown
                    sleepStagesCard

                    // Sleep Timeline
                    sleepTimelineCard

                    // Sleep Quality Tips
                    sleepQualityCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Sömn")
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
                animateChart = true
            }
        }
    }

    // MARK: - Large Sleep Ring
    private var largeSleepRing: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.vitalySleep.opacity(0.15), lineWidth: 24)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animateChart ? min(sleepPercentage / 100, 1.0) : 0)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.vitalySleep.opacity(0.6),
                                Color.vitalySleep,
                                Color.vitalySleep,
                                Color.vitalySleep.opacity(0.8)
                            ],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.vitalySleep.opacity(0.4), radius: 8, x: 0, y: 0)

                // Center content
                VStack(spacing: 8) {
                    Text(sleepData?.formattedDuration ?? "0h 0m")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Text("Total sömn")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
            .frame(width: 240, height: 240)

            // Status label
            HStack(spacing: 8) {
                Circle()
                    .fill(sleepQualityColor)
                    .frame(width: 8, height: 8)

                Text(sleepData?.quality.displayText ?? "Okänd")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(sleepQualityColor)

                Text("kvalitet")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.vitalyTextSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(sleepQualityColor.opacity(0.15))
            )
        }
        .padding(.vertical, 20)
    }

    // MARK: - Sleep Times Card
    private var sleepTimesCard: some View {
        HStack(spacing: 12) {
            // Bedtime
            VitalyCard {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.vitalySleep.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: "moon.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.vitalySleep)
                    }

                    VStack(spacing: 4) {
                        Text("Sänggående")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)

                        Text(formattedBedtime)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.vitalyTextPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            // Wake time
            VitalyCard {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.vitalyPrimary.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.vitalyPrimary)
                    }

                    VStack(spacing: 4) {
                        Text("Uppvaknande")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)

                        Text(formattedWakeTime)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.vitalyTextPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
    }

    // MARK: - Sleep Stages Card
    private var sleepStagesCard: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 20) {
                Text("SÖMNSTADIER")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .tracking(1.2)

                // Deep sleep
                SleepStageRow(
                    icon: "bed.double.fill",
                    label: "Djupsömn",
                    duration: sleepData?.deepSleep ?? 0,
                    percentage: deepSleepPercentage,
                    color: Color(red: 0.4, green: 0.3, blue: 0.7)
                )

                Divider()
                    .background(Color.vitalySurface)

                // REM sleep
                SleepStageRow(
                    icon: "moon.stars.fill",
                    label: "REM-sömn",
                    duration: sleepData?.remSleep ?? 0,
                    percentage: remSleepPercentage,
                    color: Color.vitalySleep
                )

                Divider()
                    .background(Color.vitalySurface)

                // Light sleep
                SleepStageRow(
                    icon: "cloud.moon.fill",
                    label: "Lätt sömn",
                    duration: sleepData?.lightSleep ?? 0,
                    percentage: lightSleepPercentage,
                    color: Color(red: 0.7, green: 0.6, blue: 0.9)
                )

                Divider()
                    .background(Color.vitalySurface)

                // Awake
                SleepStageRow(
                    icon: "eye.fill",
                    label: "Vaken",
                    duration: sleepData?.awake ?? 0,
                    percentage: awakePercentage,
                    color: Color.vitalyTextSecondary
                )
            }
            .padding(20)
        }
    }

    // MARK: - Sleep Timeline Card
    private var sleepTimelineCard: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("SÖMNKURVA")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .tracking(1.2)

                // Sleep stage visualization
                SleepTimelineVisualization(sleepData: sleepData)
                    .frame(height: 120)
                    .opacity(animateChart ? 1.0 : 0)

                // Time labels
                HStack {
                    Text(formattedBedtime)
                        .font(.caption)
                        .foregroundStyle(Color.vitalyTextSecondary)

                    Spacer()

                    Text("Halva natten")
                        .font(.caption)
                        .foregroundStyle(Color.vitalyTextSecondary)

                    Spacer()

                    Text(formattedWakeTime)
                        .font(.caption)
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Sleep Quality Card
    private var sleepQualityCard: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.vitalySleep)

                    Text("FÖR BÄTTRE SÖMN")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                VStack(alignment: .leading, spacing: 14) {
                    SleepTipRow(
                        icon: "clock.fill",
                        text: "Håll regelbundna sovtider - gå till sängs och vakna samtidigt varje dag"
                    )

                    SleepTipRow(
                        icon: "moon.zzz.fill",
                        text: "Skapa en mörk, sval och tyst sovmiljö (16-19°C är optimalt)"
                    )

                    SleepTipRow(
                        icon: "iphone.slash",
                        text: "Undvik skärmar 1-2 timmar före sänggåendet"
                    )

                    SleepTipRow(
                        icon: "cup.and.saucer.fill",
                        text: "Begränsa koffein efter kl 14 och alkohol före sömn"
                    )
                }
            }
            .padding(20)
        }
    }

    // MARK: - Computed Properties
    private var sleepQualityColor: Color {
        guard let quality = sleepData?.quality else { return Color.vitalyTextSecondary }
        switch quality {
        case .excellent: return Color.vitalyExcellent
        case .good: return Color.vitalyGood
        case .fair: return Color.vitalyFair
        case .poor: return Color.vitalyPoor
        }
    }

    private var deepSleepPercentage: Double {
        guard let sleep = sleepData, sleep.totalDuration > 0 else { return 0 }
        return (sleep.deepSleep / sleep.totalDuration) * 100
    }

    private var remSleepPercentage: Double {
        guard let sleep = sleepData, sleep.totalDuration > 0 else { return 0 }
        return (sleep.remSleep / sleep.totalDuration) * 100
    }

    private var lightSleepPercentage: Double {
        guard let sleep = sleepData, sleep.totalDuration > 0 else { return 0 }
        return (sleep.lightSleep / sleep.totalDuration) * 100
    }

    private var awakePercentage: Double {
        guard let sleep = sleepData, sleep.totalDuration > 0 else { return 0 }
        return (sleep.awake / sleep.totalDuration) * 100
    }

    private var formattedBedtime: String {
        guard let bedtime = sleepData?.bedtime else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: bedtime)
    }

    private var formattedWakeTime: String {
        guard let wakeTime = sleepData?.wakeTime else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: wakeTime)
    }
}

// MARK: - Sleep Stage Row
struct SleepStageRow: View {
    let icon: String
    let label: String
    let duration: TimeInterval
    let percentage: Double
    let color: Color

    private var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
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

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedDuration)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Text(String(format: "%.0f%%", percentage))
                        .font(.caption)
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.vitalySurface)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * (percentage / 100), height: 6)
                        .animation(.easeOut(duration: 1.0).delay(0.3), value: percentage)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Sleep Tip Row
struct SleepTipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.vitalySleep.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.vitalySleep)
            }

            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.vitalyTextPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Sleep Timeline Visualization
struct SleepTimelineVisualization: View {
    let sleepData: SleepData?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.vitalySurface.opacity(0.3))

                if let sleep = sleepData, sleep.totalDuration > 0 {
                    HStack(spacing: 2) {
                        // Deep sleep
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.4, green: 0.3, blue: 0.7))
                            .frame(width: geometry.size.width * (sleep.deepSleep / sleep.totalDuration))

                        // REM sleep
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.vitalySleep)
                            .frame(width: geometry.size.width * (sleep.remSleep / sleep.totalDuration))

                        // Light sleep
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.7, green: 0.6, blue: 0.9))
                            .frame(width: geometry.size.width * (sleep.lightSleep / sleep.totalDuration))

                        // Awake
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.vitalyTextSecondary.opacity(0.5))
                            .frame(width: geometry.size.width * (sleep.awake / sleep.totalDuration))
                    }
                    .padding(4)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SleepDetailView(
            sleepData: SleepData(
                id: "1",
                date: Date(),
                totalDuration: 7.5 * 3600,
                deepSleep: 1.8 * 3600,
                remSleep: 2.1 * 3600,
                lightSleep: 3.3 * 3600,
                awake: 0.3 * 3600,
                bedtime: Date().addingTimeInterval(-8 * 3600),
                wakeTime: Date()
            ),
            historicalData: []
        )
    }
    .preferredColorScheme(.dark)
}
