import SwiftUI
import Charts

struct WaistChartView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var measurementService: BodyMeasurementService

    @State private var selectedPeriod: TimePeriod = .threeMonths
    @State private var waistData: [WaistDataPoint] = []
    @State private var isLoading = true
    @State private var currentWaist: Double?
    @State private var previousWaist: Double?
    @State private var latestWaistDate: Date?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header med nuvarande midjemått
                        currentWaistHeader

                        // Tidsperiod-väljare
                        periodPicker

                        // Diagram
                        chartSection

                        // Trendanalys
                        trendsAnalysisSection

                        // Hälsorisk-info
                        healthRiskSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Waist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.vitalyPrimary)
                }
            }
            .task {
                await loadData()
            }
            .onChange(of: selectedPeriod) { _, _ in
                Task {
                    await loadData()
                }
            }
        }
    }

    // MARK: - Current Waist Header

    private var currentWaistHeader: some View {
        VitalyCard {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Current waist")
                            .font(.subheadline)
                            .foregroundStyle(Color.vitalyTextSecondary)

                        if let waist = currentWaist {
                            Text(String(format: "%.0f cm", waist))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.vitalyTextPrimary)
                        } else {
                            Text("-- cm")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }

                        if let date = latestWaistDate {
                            Text(date, format: .dateTime.day().month().year())
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }
                    }

                    Spacer()

                    // Trend indikator
                    trendIndicator
                }
            }
            .padding(20)
        }
    }

    private var trendIndicator: some View {
        Group {
            if let current = currentWaist, let previous = previousWaist {
                let diff = current - previous
                let isDecreasing = diff < 0

                HStack(spacing: 6) {
                    Image(systemName: isDecreasing ? "arrow.down.right" : "arrow.up.right")
                        .font(.system(size: 14, weight: .semibold))

                    Text(isDecreasing ? "Decreasing" : "Increasing")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(isDecreasing ? Color.vitalyExcellent : Color.vitalyHeart)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill((isDecreasing ? Color.vitalyExcellent : Color.vitalyHeart).opacity(0.15))
                )
            } else {
                Text("No trend")
                    .font(.subheadline)
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.vitalySurface)
                    )
            }
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedPeriod == period ? .white : Color.vitalyTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedPeriod == period ? Color.vitalySleep : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.vitalySurface)
        )
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VitalyCard {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .frame(height: 250)
                } else if waistData.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.arms.open")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.vitalyTextSecondary.opacity(0.5))

                        Text("No data for this period")
                            .font(.subheadline)
                            .foregroundStyle(Color.vitalyTextSecondary)

                        Text("Add waist measurements to see your trend")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary.opacity(0.7))
                    }
                    .frame(height: 250)
                } else {
                    waistChart
                        .frame(height: 250)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                }
            }
        }
    }

    private var waistChart: some View {
        Chart {
            // Midjemått-linje
            ForEach(waistData) { point in
                LineMark(
                    x: .value("Datum", point.date, unit: .day),
                    y: .value("Midjemått", point.waist)
                )
                .foregroundStyle(Color.vitalySleep)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
            }

            // Area under linjen
            ForEach(waistData) { point in
                AreaMark(
                    x: .value("Datum", point.date, unit: .day),
                    y: .value("Midjemått", point.waist)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.vitalySleep.opacity(0.3), Color.vitalySleep.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Punkter
            ForEach(waistData) { point in
                PointMark(
                    x: .value("Datum", point.date, unit: .day),
                    y: .value("Midjemått", point.waist)
                )
                .foregroundStyle(Color.vitalySleep)
                .symbolSize(50)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: xAxisStride)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.vitalySurface)
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formatAxisDate(date))
                            .font(.caption2)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.vitalySurface)
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text(String(format: "%.0f", val))
                            .font(.caption2)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }
            }
        }
    }

    private var xAxisStride: Calendar.Component {
        switch selectedPeriod {
        case .oneMonth: return .weekOfYear
        case .threeMonths: return .month
        case .sixMonths: return .month
        case .oneYear: return .month
        }
    }

    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        switch selectedPeriod {
        case .oneMonth:
            formatter.dateFormat = "d MMM"
        case .threeMonths, .sixMonths, .oneYear:
            formatter.dateFormat = "MMM"
        }
        return formatter.string(from: date)
    }

    // MARK: - Trends Analysis Section

    private var trendsAnalysisSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(Color.vitalySleep)
                    Text("TREND ANALYSIS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                Divider()
                    .background(Color.vitalySurface)

                // Total change
                if let first = waistData.first, let last = waistData.last, waistData.count > 1 {
                    let change = last.waist - first.waist
                    trendRow(
                        title: "Total change",
                        value: String(format: "%+.0f cm", change),
                        valueColor: change < 0 ? .vitalyExcellent : (change > 0 ? Color.vitalyHeart : Color.vitalyTextSecondary)
                    )

                    Divider()
                        .background(Color.vitalySurface)
                }

                // Weekly average
                trendRow(
                    title: "Weekly average",
                    value: calculateWeeklyAverage()
                )

                Divider()
                    .background(Color.vitalySurface)

                // 30-day projection
                trendRow(
                    title: "30-day projection",
                    value: calculateProjection()
                )
            }
            .padding(20)
        }
    }

    private func trendRow(title: String, value: String, valueColor: Color = Color.vitalyTextPrimary) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.vitalyTextSecondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(valueColor)
        }
    }

    private func calculateWeeklyAverage() -> String {
        guard waistData.count >= 2 else { return "No data" }

        let sortedData = waistData.sorted { $0.date < $1.date }
        guard let first = sortedData.first, let last = sortedData.last else { return "No data" }

        let daysBetween = Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 1
        guard daysBetween > 0 else { return "No data" }

        let waistChange = last.waist - first.waist
        let weeklyChange = (waistChange / Double(daysBetween)) * 7

        if abs(weeklyChange) < 0.1 {
            return "Stable"
        }

        return String(format: "%+.1f cm", weeklyChange)
    }

    private func calculateProjection() -> String {
        guard waistData.count >= 2 else { return "No data" }

        let sortedData = waistData.sorted { $0.date < $1.date }
        guard let first = sortedData.first, let last = sortedData.last else { return "No data" }

        let daysBetween = Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 1
        guard daysBetween > 0 else { return "No data" }

        let waistChange = last.waist - first.waist
        let dailyChange = waistChange / Double(daysBetween)
        let projectedChange = dailyChange * 30

        if abs(projectedChange) < 0.5 {
            return "Stable"
        }

        return String(format: "%+.0f cm", projectedChange)
    }

    // MARK: - Health Risk Section

    private var healthRiskSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundStyle(Color.vitalyHeart)
                    Text("HEALTH RISK")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                Divider()
                    .background(Color.vitalySurface)

                if let waist = currentWaist {
                    let riskLevel = calculateRiskLevel(waist: waist)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(riskLevel.title)
                                .font(.headline)
                                .foregroundStyle(riskLevel.color)

                            Text(riskLevel.description)
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Circle()
                            .fill(riskLevel.color)
                            .frame(width: 12, height: 12)
                    }

                    // Reference values
                    Divider()
                        .background(Color.vitalySurface)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reference values (men/women)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.vitalyTextSecondary)

                        HStack(spacing: 16) {
                            referenceItem(label: "Low risk", value: "< 94 / 80 cm", color: .vitalyExcellent)
                            referenceItem(label: "High risk", value: "> 102 / 88 cm", color: .vitalyHeart)
                        }
                    }
                } else {
                    Text("Add waist measurements to see your health risk")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
            .padding(20)
        }
    }

    private func referenceItem(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.vitalyTextSecondary)
            }
            Text(value)
                .font(.caption)
                .foregroundStyle(Color.vitalyTextPrimary)
        }
    }

    private func calculateRiskLevel(waist: Double) -> (title: String, description: String, color: Color) {
        // Using male reference values as default
        // In the future, gender selection can be added
        if waist < 94 {
            return ("Low risk", "Your waist measurement is within the healthy range.", .vitalyExcellent)
        } else if waist < 102 {
            return ("Elevated risk", "Your waist measurement indicates slightly elevated health risk.", .vitalyRecovery)
        } else {
            return ("High risk", "Your waist measurement indicates increased risk of cardiovascular disease.", .vitalyHeart)
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Ladda alltid senaste Firestore-data
        await measurementService.fetchMeasurements(limit: 365)

        let days = selectedPeriod.days
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        // Filtrera mätningar med midjemått inom perioden
        let filteredMeasurements = measurementService.measurements
            .filter { $0.waistCircumference != nil && $0.date >= startDate }
            .sorted { $0.date < $1.date }

        waistData = filteredMeasurements.map { measurement in
            WaistDataPoint(date: measurement.date, waist: measurement.waistCircumference!)
        }

        currentWaist = waistData.last?.waist ?? measurementService.latestWaist
        previousWaist = waistData.count > 1 ? waistData[waistData.count - 2].waist : nil
        latestWaistDate = waistData.last?.date
    }
}

// WaistDataPoint and TimePeriod are defined in BiologyView.swift

#Preview {
    WaistChartView(measurementService: BodyMeasurementService())
}
