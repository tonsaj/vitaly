import SwiftUI
import Charts

struct SleepDetailView: View {
    let sleepData: SleepData
    let historicalData: [SleepData]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Main Sleep Duration Card
                mainDurationCard

                // Sleep Quality Score
                qualityScoreCard

                // Sleep Stages Breakdown
                sleepStagesCard

                // Bedtime & Wake Time
                timingsCard

                // Week Trend Chart
                trendChartCard
            }
            .padding()
        }
        .background(Color.vitalyBackground)
        .navigationTitle("Sömn")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Main Duration Card
    private var mainDurationCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 50))
                .foregroundStyle(LinearGradient.vitalySleepGradient)

            VStack(spacing: 4) {
                Text(sleepData.formattedDuration)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.vitalyTextPrimary)

                Text("Total sömn")
                    .font(.subheadline)
                    .foregroundColor(.vitalyTextSecondary)
            }

            // Goal comparison
            HStack(spacing: 4) {
                Image(systemName: sleepData.totalHours >= 7 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(sleepData.totalHours >= 7 ? .vitalyExcellent : .vitalyFair)
                Text(goalText)
                    .font(.footnote)
                    .foregroundColor(.vitalyTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.vitalyCardBackground)
        )
    }

    private var goalText: String {
        let difference = sleepData.totalHours - 8.0
        if difference >= 0 {
            return "Mål uppnått"
        } else {
            let hours = Int(abs(difference))
            let minutes = Int((abs(difference) - Double(hours)) * 60)
            if hours > 0 {
                return "\(hours)h \(minutes)m under mål"
            } else {
                return "\(minutes)m under mål"
            }
        }
    }

    // MARK: - Quality Score Card
    private var qualityScoreCard: some View {
        HStack(spacing: 20) {
            // Circular score indicator
            ZStack {
                Circle()
                    .stroke(Color.vitalySurface, lineWidth: 12)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: CGFloat(sleepData.quality.score) / 100)
                    .stroke(
                        qualityColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(sleepData.quality.score)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.vitalyTextPrimary)
                    Text("poäng")
                        .font(.caption2)
                        .foregroundColor(.vitalyTextSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Sömnkvalitet")
                    .font(.headline)
                    .foregroundColor(.vitalyTextPrimary)

                Text(sleepData.quality.displayText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(qualityColor)

                Text(qualityDescription)
                    .font(.caption)
                    .foregroundColor(.vitalyTextSecondary)
                    .lineLimit(3)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
        )
    }

    private var qualityColor: Color {
        switch sleepData.quality {
        case .excellent: return .vitalyExcellent
        case .good: return .vitalyGood
        case .fair: return .vitalyFair
        case .poor: return .vitalyPoor
        }
    }

    private var qualityDescription: String {
        switch sleepData.quality {
        case .excellent:
            return "Utmärkt sömn med optimala djupsömn- och REM-nivåer"
        case .good:
            return "Bra sömn som främjar återhämtning"
        case .fair:
            return "Godtagbar sömn, men kan förbättras"
        case .poor:
            return "Sömnkvaliteten behöver förbättras"
        }
    }

    // MARK: - Sleep Stages Card
    private var sleepStagesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sömnfaser")
                .font(.headline)
                .foregroundColor(.vitalyTextPrimary)

            VStack(spacing: 12) {
                sleepStageRow(
                    name: "Djupsömn",
                    duration: sleepData.deepSleep,
                    color: Color(red: 0.5, green: 0.4, blue: 0.75),
                    icon: "moon.zzz.fill"
                )

                sleepStageRow(
                    name: "REM-sömn",
                    duration: sleepData.remSleep,
                    color: Color.vitalySleep,
                    icon: "brain.head.profile"
                )

                sleepStageRow(
                    name: "Lätt sömn",
                    duration: sleepData.lightSleep,
                    color: Color(red: 0.7, green: 0.6, blue: 0.9),
                    icon: "cloud.moon.fill"
                )

                sleepStageRow(
                    name: "Vaken",
                    duration: sleepData.awake,
                    color: Color.vitalyFair,
                    icon: "eye.fill"
                )
            }

            // Visual breakdown bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    stageBar(
                        width: geometry.size.width * (sleepData.deepSleep / sleepData.totalDuration),
                        color: Color(red: 0.5, green: 0.4, blue: 0.75)
                    )
                    stageBar(
                        width: geometry.size.width * (sleepData.remSleep / sleepData.totalDuration),
                        color: Color.vitalySleep
                    )
                    stageBar(
                        width: geometry.size.width * (sleepData.lightSleep / sleepData.totalDuration),
                        color: Color(red: 0.7, green: 0.6, blue: 0.9)
                    )
                    stageBar(
                        width: geometry.size.width * (sleepData.awake / sleepData.totalDuration),
                        color: Color.vitalyFair
                    )
                }
            }
            .frame(height: 16)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
        )
    }

    private func sleepStageRow(name: String, duration: TimeInterval, color: Color, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 28)

            Text(name)
                .font(.subheadline)
                .foregroundColor(.vitalyTextPrimary)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDuration(duration))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.vitalyTextPrimary)

                Text(String(format: "%.0f%%", (duration / sleepData.totalDuration) * 100))
                    .font(.caption2)
                    .foregroundColor(.vitalyTextSecondary)
            }
        }
    }

    private func stageBar(width: CGFloat, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: max(2, width))
    }

    // MARK: - Timings Card
    private var timingsCard: some View {
        HStack(spacing: 16) {
            // Bedtime
            VStack(spacing: 8) {
                Image(systemName: "moon.fill")
                    .font(.title2)
                    .foregroundColor(.vitalySleep)

                Text("Läggdags")
                    .font(.caption)
                    .foregroundColor(.vitalyTextSecondary)

                if let bedtime = sleepData.bedtime {
                    Text(formatTime(bedtime))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.vitalyTextPrimary)
                } else {
                    Text("—")
                        .font(.title3)
                        .foregroundColor(.vitalyTextSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.vitalyCardBackground)
            )

            // Wake time
            VStack(spacing: 8) {
                Image(systemName: "sunrise.fill")
                    .font(.title2)
                    .foregroundColor(.vitalyPrimary)

                Text("Uppvakning")
                    .font(.caption)
                    .foregroundColor(.vitalyTextSecondary)

                if let wakeTime = sleepData.wakeTime {
                    Text(formatTime(wakeTime))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.vitalyTextPrimary)
                } else {
                    Text("—")
                        .font(.title3)
                        .foregroundColor(.vitalyTextSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.vitalyCardBackground)
            )
        }
    }

    // MARK: - Trend Chart Card
    private var trendChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Veckotrend")
                    .font(.headline)
                    .foregroundColor(.vitalyTextPrimary)

                Spacer()

                Text("Mål: 8h")
                    .font(.caption)
                    .foregroundColor(.vitalyTextSecondary)
            }

            Chart {
                // Goal line
                RuleMark(y: .value("Mål", 8.0))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(Color.vitalyTextSecondary.opacity(0.3))

                ForEach(historicalData) { data in
                    BarMark(
                        x: .value("Dag", data.date, unit: .day),
                        y: .value("Timmar", data.totalHours)
                    )
                    .foregroundStyle(LinearGradient.vitalySleepGradient)
                    .cornerRadius(6)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(formatShortWeekday(date))
                                .font(.caption2)
                                .foregroundColor(.vitalyTextSecondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text("\(Int(hours))h")
                                .font(.caption2)
                                .foregroundColor(.vitalyTextSecondary)
                        }
                    }
                }
            }
            .frame(height: 180)

            // Average
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundColor(.vitalySleep)

                Text("Genomsnitt: \(averageHours)")
                    .font(.caption)
                    .foregroundColor(.vitalyTextSecondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
        )
    }

    private var averageHours: String {
        let total = historicalData.reduce(0) { $0 + $1.totalHours }
        let average = total / Double(historicalData.count)
        let hours = Int(average)
        let minutes = Int((average - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }

    // MARK: - Helper Functions
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatShortWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter.string(from: date).capitalized
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SleepDetailView(
            sleepData: SleepData(
                id: "1",
                date: Date(),
                totalDuration: 7.5 * 3600,
                deepSleep: 1.8 * 3600,
                remSleep: 1.5 * 3600,
                lightSleep: 3.8 * 3600,
                awake: 0.4 * 3600,
                bedtime: Calendar.current.date(bySettingHour: 23, minute: 15, second: 0, of: Date()),
                wakeTime: Calendar.current.date(bySettingHour: 6, minute: 45, second: 0, of: Date())
            ),
            historicalData: (0..<7).map { dayOffset in
                SleepData(
                    id: "\(dayOffset)",
                    date: Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!,
                    totalDuration: Double.random(in: 6...9) * 3600,
                    deepSleep: 1.5 * 3600,
                    remSleep: 1.3 * 3600,
                    lightSleep: 3.5 * 3600,
                    awake: 0.3 * 3600,
                    bedtime: nil,
                    wakeTime: nil
                )
            }
        )
    }
}
