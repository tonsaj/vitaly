import SwiftUI
import Charts

struct TrendChartView: View {
    let metricType: MetricType
    let dataPoints: [ChartDataPoint]

    var body: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                // Chart header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SENASTE 7 DAGARNA")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                            .tracking(1)

                        if let latest = dataPoints.last {
                            Text(latest.formattedValue)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(Color.vitalyTextPrimary)
                        }
                    }

                    Spacer()

                    // Metric icon
                    ZStack {
                        Circle()
                            .fill(metricType.vitalyColor.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: metricType.icon)
                            .font(.body)
                            .foregroundStyle(metricType.vitalyColor)
                    }
                }

                // Chart
                Chart {
                    ForEach(dataPoints) { point in
                        LineMark(
                            x: .value("Datum", point.date, unit: .day),
                            y: .value("Värde", point.value)
                        )
                        .foregroundStyle(metricType.vitalyGradient)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                        AreaMark(
                            x: .value("Datum", point.date, unit: .day),
                            y: .value("Värde", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    metricType.vitalyColor.opacity(0.3),
                                    metricType.vitalyColor.opacity(0.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Datum", point.date, unit: .day),
                            y: .value("Värde", point.value)
                        )
                        .foregroundStyle(metricType.vitalyColor)
                        .symbolSize(point == dataPoints.last ? 120 : 60)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(formatDate(date))
                                    .font(.caption2)
                                    .foregroundStyle(Color.vitalyTextSecondary)
                            }
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.vitalySurface)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.vitalySurface)
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(formatYAxis(doubleValue))
                                    .font(.caption2)
                                    .foregroundStyle(Color.vitalyTextSecondary)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(Color.vitalyBackground.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(20)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter.string(from: date).capitalized
    }

    private func formatYAxis(_ value: Double) -> String {
        switch metricType {
        case .sleep:
            return "\(Int(value))h"
        case .activity:
            return "\(Int(value / 1000))k"
        case .heart:
            return "\(Int(value))"
        case .recovery:
            return "\(Int(value))"
        }
    }
}

// MARK: - Chart Data Point
struct ChartDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
    let formattedValue: String

    static func == (lhs: ChartDataPoint, rhs: ChartDataPoint) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preview
#Preview("Sleep Trend") {
    ZStack {
        Color.vitalyBackground.ignoresSafeArea()

        let calendar = Calendar.current
        let today = Date()

        let sleepData = (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -6 + offset, to: today)!
            let hours = Double.random(in: 6.5...8.5)
            return ChartDataPoint(
                date: date,
                value: hours,
                formattedValue: String(format: "%.1fh", hours)
            )
        }

        TrendChartView(
            metricType: .sleep,
            dataPoints: sleepData
        )
        .padding()
    }
}

#Preview("All Metric Trends") {
    ZStack {
        Color.vitalyBackground.ignoresSafeArea()

        ScrollView {
            let calendar = Calendar.current
            let today = Date()

            VStack(spacing: 16) {
                // Sleep
                TrendChartView(
                    metricType: .sleep,
                    dataPoints: (0..<7).map { offset in
                        let date = calendar.date(byAdding: .day, value: -6 + offset, to: today)!
                        let hours = Double.random(in: 6.5...8.5)
                        return ChartDataPoint(
                            date: date,
                            value: hours,
                            formattedValue: String(format: "%.1fh", hours)
                        )
                    }
                )

                // Activity
                TrendChartView(
                    metricType: .activity,
                    dataPoints: (0..<7).map { offset in
                        let date = calendar.date(byAdding: .day, value: -6 + offset, to: today)!
                        let steps = Double.random(in: 4000...12000)
                        return ChartDataPoint(
                            date: date,
                            value: steps,
                            formattedValue: "\(Int(steps)) steg"
                        )
                    }
                )

                // Heart
                TrendChartView(
                    metricType: .heart,
                    dataPoints: (0..<7).map { offset in
                        let date = calendar.date(byAdding: .day, value: -6 + offset, to: today)!
                        let bpm = Double.random(in: 55...65)
                        return ChartDataPoint(
                            date: date,
                            value: bpm,
                            formattedValue: "\(Int(bpm)) bpm"
                        )
                    }
                )

                // Recovery
                TrendChartView(
                    metricType: .recovery,
                    dataPoints: (0..<7).map { offset in
                        let date = calendar.date(byAdding: .day, value: -6 + offset, to: today)!
                        let recovery = Double.random(in: 70...95)
                        return ChartDataPoint(
                            date: date,
                            value: recovery,
                            formattedValue: "\(Int(recovery))%"
                        )
                    }
                )
            }
            .padding()
        }
    }
}
