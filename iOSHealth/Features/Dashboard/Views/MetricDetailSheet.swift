import SwiftUI
import Charts

struct MetricDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let metric: DashboardMetric
    let currentValue: Double
    let yesterdayValue: Double
    let weekData: [Double]

    @State private var animateChart = false

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
                    VStack(spacing: 24) {
                        // Nuvarande värde
                        currentValueCard

                        // Jämförelse med igår
                        comparisonCard

                        // 7-dagars trend
                        trendChartCard

                        // Statistik
                        statisticsCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
    }

    // MARK: - Nuvarande Värde
    private var currentValueCard: some View {
        VitalyCard {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(metric.color.opacity(0.2))
                            .frame(width: 56, height: 56)

                        Image(systemName: metric.icon)
                            .font(.system(size: 24))
                            .foregroundStyle(metric.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Idag")
                            .font(.subheadline)
                            .foregroundStyle(Color.vitalyTextSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(formattedValue(currentValue))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.vitalyTextPrimary)

                            Text(metric.unit)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }
                    }

                    Spacer()
                }
            }
            .padding(20)
        }
    }

    // MARK: - Jämförelse med igår
    private var comparisonCard: some View {
        VitalyCard {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("JÄMFÖRT MED IGÅR")
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
                    Text("Igår")
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
                Text("SENASTE 7 DAGARNA")
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

    // MARK: - Statistik
    private var statisticsCard: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("STATISTIK (7 DAGAR)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .tracking(1.2)

                HStack(spacing: 0) {
                    StatBox(
                        label: "Snitt",
                        value: formattedValue(weekData.reduce(0, +) / Double(weekData.count)),
                        unit: metric.unit,
                        color: metric.color
                    )

                    Divider()
                        .frame(height: 50)
                        .background(Color.vitalySurface)

                    StatBox(
                        label: "Högsta",
                        value: formattedValue(weekData.max() ?? 0),
                        unit: metric.unit,
                        color: .vitalyExcellent
                    )

                    Divider()
                        .frame(height: 50)
                        .background(Color.vitalySurface)

                    StatBox(
                        label: "Lägsta",
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
        let days = ["Mån", "Tis", "Ons", "Tor", "Fre", "Lör", "Sön"]
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

#Preview {
    MetricDetailSheet(
        metric: .hrv,
        currentValue: 55,
        yesterdayValue: 52,
        weekData: [52, 48, 55, 50, 53, 58, 55]
    )
    .preferredColorScheme(.dark)
}
