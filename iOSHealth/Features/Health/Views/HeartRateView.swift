import SwiftUI
import Charts

struct HeartRateView: View {
    let heartData: HeartData
    let historicalData: [HeartData]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Resting Heart Rate Card
                restingHeartRateCard

                // HRV Display
                hrvCard

                // Heart Rate Stats
                heartRateStatsCard

                // Heart Rate Zones
                heartRateZonesCard

                // Trend Chart
                trendChartCard
            }
            .padding()
        }
        .background(Color.vitalyBackground)
        .navigationTitle("Hjärta")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Resting Heart Rate Card
    private var restingHeartRateCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundStyle(LinearGradient.vitalyHeartGradient)
                .symbolEffect(.pulse)

            VStack(spacing: 4) {
                Text("\(Int(heartData.restingHeartRate))")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(.vitalyTextPrimary)

                Text("bpm")
                    .font(.title3)
                    .foregroundColor(.vitalyTextSecondary)
            }

            VStack(spacing: 4) {
                Text("Vilopuls")
                    .font(.subheadline)
                    .foregroundColor(.vitalyTextSecondary)

                HStack(spacing: 6) {
                    Image(systemName: restingHRStatusIcon)
                        .font(.caption)
                        .foregroundColor(restingHRStatusColor)
                    Text(heartData.restingHRStatus.displayText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(restingHRStatusColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.vitalyCardBackground)
        )
    }

    private var restingHRStatusIcon: String {
        switch heartData.restingHRStatus {
        case .athletic, .excellent: return "checkmark.seal.fill"
        case .good: return "checkmark.circle.fill"
        case .average: return "minus.circle.fill"
        case .elevated: return "exclamationmark.triangle.fill"
        }
    }

    private var restingHRStatusColor: Color {
        switch heartData.restingHRStatus {
        case .athletic, .excellent: return .vitalyExcellent
        case .good: return .vitalyGood
        case .average: return .vitalyFair
        case .elevated: return .vitalyPoor
        }
    }

    // MARK: - HRV Card
    private var hrvCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.title3)
                    .foregroundColor(Color(red: 0.4, green: 0.75, blue: 0.85))

                Text("Hjärtfrekvensvariabilitet")
                    .font(.headline)
                    .foregroundColor(.vitalyTextPrimary)

                Spacer()
            }

            if let hrv = heartData.hrv {
                HStack(alignment: .bottom, spacing: 8) {
                    Text(String(format: "%.0f", hrv))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.vitalyTextPrimary)

                    Text("ms")
                        .font(.title3)
                        .foregroundColor(.vitalyTextSecondary)
                        .padding(.bottom, 6)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(hrvStatusColor)
                                .frame(width: 8, height: 8)
                            Text(heartData.hrvStatus.displayText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(hrvStatusColor)
                        }

                        Text(hrvDescription)
                            .font(.caption)
                            .foregroundColor(.vitalyTextSecondary)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // HRV Status Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background gradient showing zones
                        LinearGradient(
                            colors: [.vitalyPoor, .vitalyFair, .vitalyGood, .vitalyExcellent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 12)
                        .cornerRadius(6)
                        .opacity(0.3)

                        // Current position indicator
                        Circle()
                            .fill(hrvStatusColor)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.vitalyTextPrimary, lineWidth: 3)
                            )
                            .shadow(color: hrvStatusColor.opacity(0.4), radius: 4, x: 0, y: 2)
                            .offset(x: min(max(CGFloat(hrv / 100.0) * geometry.size.width - 10, 0), geometry.size.width - 20))
                    }
                }
                .frame(height: 20)

            } else {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.vitalyTextSecondary)
                    Text("Inga HRV-data tillgängliga")
                        .font(.subheadline)
                        .foregroundColor(.vitalyTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
        )
    }

    private var hrvStatusColor: Color {
        switch heartData.hrvStatus {
        case .excellent: return .vitalyExcellent
        case .good: return .vitalyGood
        case .fair: return .vitalyFair
        case .low: return .vitalyPoor
        case .unknown: return .vitalyTextSecondary
        }
    }

    private var hrvDescription: String {
        switch heartData.hrvStatus {
        case .excellent: return "Utmärkt återhämtning"
        case .good: return "Bra variabilitet"
        case .fair: return "Normal variabilitet"
        case .low: return "Låg variabilitet"
        case .unknown: return "Ingen data"
        }
    }

    // MARK: - Heart Rate Stats Card
    private var heartRateStatsCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statCard(
                    title: "Genomsnitt",
                    value: "\(Int(heartData.averageHeartRate))",
                    subtitle: "bpm",
                    icon: "heart.circle.fill",
                    color: Color.vitalyHeart
                )

                statCard(
                    title: "Max",
                    value: "\(Int(heartData.maxHeartRate))",
                    subtitle: "bpm",
                    icon: "arrow.up.circle.fill",
                    color: Color.vitalyPoor
                )
            }

            HStack(spacing: 12) {
                statCard(
                    title: "Min",
                    value: "\(Int(heartData.minHeartRate))",
                    subtitle: "bpm",
                    icon: "arrow.down.circle.fill",
                    color: Color(red: 0.4, green: 0.6, blue: 0.95)
                )

                statCard(
                    title: "Vila",
                    value: "\(Int(heartData.restingHeartRate))",
                    subtitle: "bpm",
                    icon: "moon.circle.fill",
                    color: Color(red: 0.7, green: 0.5, blue: 0.85)
                )
            }
        }
    }

    private func statCard(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.vitalyTextPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.vitalyTextSecondary)
                }

                Text(title)
                    .font(.caption)
                    .foregroundColor(.vitalyTextSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
        )
    }

    // MARK: - Heart Rate Zones Card
    private var heartRateZonesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundColor(.vitalyHeart)

                Text("Pulszoner")
                    .font(.headline)
                    .foregroundColor(.vitalyTextPrimary)

                Spacer()

                Text("Idag")
                    .font(.caption)
                    .foregroundColor(.vitalyTextSecondary)
            }

            VStack(spacing: 12) {
                ForEach(heartData.heartRateZones.sorted(by: { $0.zone < $1.zone })) { zone in
                    heartRateZoneRow(zone)
                }
            }

            // Total time in zones
            HStack {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.vitalyHeart)

                Text("Total tid i zoner: \(totalZoneTime)")
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

    private func heartRateZoneRow(_ zone: HeartRateZone) -> some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(zoneColor(zone.zone))
                        .frame(width: 12, height: 12)

                    Text(zone.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.vitalyTextPrimary)

                    Text("\(zone.minBPM)-\(zone.maxBPM)")
                        .font(.caption)
                        .foregroundColor(.vitalyTextSecondary)
                }

                Spacer()

                Text(zone.formattedDuration)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.vitalyTextPrimary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.vitalySurface)
                        .frame(height: 6)
                        .cornerRadius(3)

                    Rectangle()
                        .fill(zoneColor(zone.zone))
                        .frame(width: geometry.size.width * CGFloat(zone.duration / totalZoneDuration), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }

    private func zoneColor(_ zone: Int) -> Color {
        switch zone {
        case 1: return Color(red: 0.4, green: 0.6, blue: 0.95)
        case 2: return .vitalyExcellent
        case 3: return .vitalyFair
        case 4: return .vitalyActivity
        case 5: return .vitalyPoor
        default: return .vitalyTextSecondary
        }
    }

    private var totalZoneDuration: TimeInterval {
        heartData.heartRateZones.reduce(0) { $0 + $1.duration }
    }

    private var totalZoneTime: String {
        let hours = Int(totalZoneDuration) / 3600
        let minutes = (Int(totalZoneDuration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    // MARK: - Trend Chart Card
    private var trendChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Vilopuls trend")
                    .font(.headline)
                    .foregroundColor(.vitalyTextPrimary)

                Spacer()

                Text("7 dagar")
                    .font(.caption)
                    .foregroundColor(.vitalyTextSecondary)
            }

            Chart {
                ForEach(historicalData) { data in
                    LineMark(
                        x: .value("Dag", data.date, unit: .day),
                        y: .value("BPM", data.restingHeartRate)
                    )
                    .foregroundStyle(LinearGradient.vitalyHeartGradient)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Dag", data.date, unit: .day),
                        y: .value("BPM", data.restingHeartRate)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                Color.vitalyHeart.opacity(0.3),
                                Color.vitalyHeart.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Dag", data.date, unit: .day),
                        y: .value("BPM", data.restingHeartRate)
                    )
                    .foregroundStyle(Color.vitalyHeart)
                    .symbol(.circle)
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
                        if let bpm = value.as(Double.self) {
                            Text("\(Int(bpm))")
                                .font(.caption2)
                                .foregroundColor(.vitalyTextSecondary)
                        }
                    }
                }
            }
            .frame(height: 180)

            // Statistics
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Genomsnitt")
                        .font(.caption)
                        .foregroundColor(.vitalyTextSecondary)
                    Text("\(Int(averageRestingHR)) bpm")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.vitalyTextPrimary)
                }

                Divider()
                    .frame(height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Trend")
                        .font(.caption)
                        .foregroundColor(.vitalyTextSecondary)
                    HStack(spacing: 4) {
                        Image(systemName: trendIcon)
                            .font(.caption)
                        Text(trendText)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(trendColor)
                }

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
        )
    }

    private var averageRestingHR: Double {
        let total = historicalData.reduce(0.0) { $0 + $1.restingHeartRate }
        return total / Double(historicalData.count)
    }

    private var trendIcon: String {
        if historicalData.count < 2 { return "minus" }
        let first = historicalData.first!.restingHeartRate
        let last = historicalData.last!.restingHeartRate
        if last < first - 2 { return "arrow.down.right" }
        if last > first + 2 { return "arrow.up.right" }
        return "arrow.right"
    }

    private var trendText: String {
        if historicalData.count < 2 { return "Stabil" }
        let first = historicalData.first!.restingHeartRate
        let last = historicalData.last!.restingHeartRate
        if last < first - 2 { return "Förbättras" }
        if last > first + 2 { return "Ökar" }
        return "Stabil"
    }

    private var trendColor: Color {
        if historicalData.count < 2 { return .vitalyTextSecondary }
        let first = historicalData.first!.restingHeartRate
        let last = historicalData.last!.restingHeartRate
        if last < first - 2 { return .vitalyExcellent }
        if last > first + 2 { return .vitalyFair }
        return .vitalyTextSecondary
    }

    // MARK: - Helper Functions
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
        HeartRateView(
            heartData: HeartData(
                id: "1",
                date: Date(),
                restingHeartRate: 58,
                averageHeartRate: 72,
                maxHeartRate: 165,
                minHeartRate: 52,
                hrv: 62,
                heartRateZones: [
                    HeartRateZone(id: "1", zone: 1, name: "Vila", duration: 72000, minBPM: 50, maxBPM: 90),
                    HeartRateZone(id: "2", zone: 2, name: "Lätt", duration: 7200, minBPM: 90, maxBPM: 120),
                    HeartRateZone(id: "3", zone: 3, name: "Aerob", duration: 1800, minBPM: 120, maxBPM: 140),
                    HeartRateZone(id: "4", zone: 4, name: "Anaerob", duration: 900, minBPM: 140, maxBPM: 160),
                    HeartRateZone(id: "5", zone: 5, name: "Max", duration: 300, minBPM: 160, maxBPM: 180)
                ]
            ),
            historicalData: (0..<7).map { dayOffset in
                HeartData(
                    id: "\(dayOffset)",
                    date: Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!,
                    restingHeartRate: Double.random(in: 55...65),
                    averageHeartRate: 75,
                    maxHeartRate: 170,
                    minHeartRate: 50,
                    hrv: Double.random(in: 50...70),
                    heartRateZones: []
                )
            }
        )
    }
}
