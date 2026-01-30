import SwiftUI
import Charts

struct WeightChartView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var measurementService: BodyMeasurementService
    let healthKitService: HealthKitService

    @State private var selectedPeriod: TimePeriod = .oneMonth
    @State private var weightData: [WeightDataPoint] = []
    @State private var isLoading = true
    @State private var currentWeight: Double?
    @State private var previousWeight: Double?
    @State private var latestWeightDate: Date?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header med nuvarande vikt
                        currentWeightHeader

                        // Tidsperiod-väljare
                        periodPicker

                        // Diagram
                        chartSection

                        // Legend
                        legendSection

                        // Trendanalys
                        trendsAnalysisSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Weight")
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

    // MARK: - Current Weight Header

    private var currentWeightHeader: some View {
        VitalyCard {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Current weight")
                            .font(.subheadline)
                            .foregroundStyle(Color.vitalyTextSecondary)

                        if let weight = currentWeight {
                            Text(String(format: "%.1f kg", weight))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.vitalyTextPrimary)
                        } else {
                            Text("-- kg")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }

                        if let date = latestWeightDate {
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
            if let current = currentWeight, let previous = previousWeight {
                let diff = current - previous
                let isDecreasing = diff < 0

                HStack(spacing: 6) {
                    Image(systemName: isDecreasing ? "arrow.down.right" : "arrow.up.right")
                        .font(.system(size: 14, weight: .semibold))

                    Text(isDecreasing ? "Decreasing" : "Increasing")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(isDecreasing ? Color.green : Color.vitalyPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill((isDecreasing ? Color.green : Color.vitalyPrimary).opacity(0.15))
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
                                .fill(selectedPeriod == period ? Color.vitalyPrimary : Color.clear)
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
                } else if weightData.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.vitalyTextSecondary.opacity(0.5))

                        Text("No data for this period")
                            .font(.subheadline)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                    .frame(height: 250)
                } else {
                    combinedChart
                        .frame(height: 250)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                }
            }
        }
    }

    private var combinedChart: some View {
        Chart {
            // Vikt-linje
            ForEach(weightData) { point in
                LineMark(
                    x: .value("Datum", point.date, unit: .day),
                    y: .value("Vikt", point.normalizedValue)
                )
                .foregroundStyle(Color.vitalySleep)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                .interpolationMethod(.catmullRom)
            }

            // Vikt-punkter
            ForEach(weightData) { point in
                PointMark(
                    x: .value("Datum", point.date, unit: .day),
                    y: .value("Vikt", point.normalizedValue)
                )
                .foregroundStyle(Color.vitalySleep)
                .symbolSize(40)
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
                        Text(formatYAxisValue(val))
                            .font(.caption2)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }
            }
        }
        .chartYScale(domain: 0...100)
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

    private func formatYAxisValue(_ value: Double) -> String {
        if !weightData.isEmpty {
            let minWeight = weightData.map(\.weight).min() ?? 0
            let maxWeight = weightData.map(\.weight).max() ?? 100
            let range = maxWeight - minWeight
            let actualValue = minWeight + (value / 100.0 * range)
            return String(format: "%.0f", actualValue)
        }
        return ""
    }

    // MARK: - Legend Section

    private var legendSection: some View {
        HStack(spacing: 24) {
            legendItem(color: Color.vitalySleep, label: "Weight", isDashed: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func legendItem(color: Color, label: String, isDashed: Bool) -> some View {
        HStack(spacing: 8) {
            if isDashed {
                HStack(spacing: 2) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color)
                            .frame(width: 6, height: 3)
                    }
                }
                .frame(width: 24)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 24, height: 12)
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
    }

    // MARK: - Trends Analysis Section

    private var trendsAnalysisSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(Color.vitalyPrimary)
                    Text("TREND ANALYSIS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                Divider()
                    .background(Color.vitalySurface)

                // Previous weight
                trendRow(
                    title: "Previous weight",
                    value: previousWeight.map { String(format: "%.1f kg", $0) } ?? "No data"
                )

                Divider()
                    .background(Color.vitalySurface)

                // 30-day projection
                trendRow(
                    title: "30-day projection",
                    value: calculateProjection()
                )

                if let current = currentWeight, let previous = previousWeight {
                    Divider()
                        .background(Color.vitalySurface)

                    // Change
                    let change = current - previous
                    trendRow(
                        title: "Change",
                        value: String(format: "%+.1f kg", change),
                        valueColor: change < 0 ? .green : (change > 0 ? Color.vitalyPrimary : Color.vitalyTextSecondary)
                    )
                }
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

    private func calculateProjection() -> String {
        guard weightData.count >= 2 else { return "No data" }

        let sortedData = weightData.sorted { $0.date < $1.date }
        guard let first = sortedData.first, let last = sortedData.last else { return "No data" }

        let daysBetween = Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 1
        guard daysBetween > 0 else { return "No data" }

        let weightChange = last.weight - first.weight
        let dailyChange = weightChange / Double(daysBetween)
        let projectedChange = dailyChange * 30

        if abs(projectedChange) < 0.1 {
            return "Stable"
        }

        return String(format: "%+.1f kg", projectedChange)
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        let days = selectedPeriod.days
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        // Ladda alltid senaste Firestore-data
        await measurementService.fetchMeasurements(limit: 365)

        // Hämta Firestore-data inom tidsperioden
        let firestoreWeights = measurementService.measurements
            .filter { $0.weight != nil && $0.date >= cutoffDate }
            .map { DailyValue(date: $0.date, value: $0.weight!) }

        // Slå ihop och sortera - prioritera Firestore om samma datum finns
        var allWeights: [DailyValue] = firestoreWeights

        // Försök hämta HealthKit-data (ignorera fel om inte auktoriserad)
        do {
            let healthKitWeights = try await healthKitService.fetchWeightHistory(for: days)

            // Lägg till HealthKit-data om inte samma datum finns
            for hk in healthKitWeights where hk.value > 0 {
                if !allWeights.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: hk.date) }) {
                    allWeights.append(hk)
                }
            }
        } catch {
            // HealthKit inte auktoriserad - fortsätt med bara Firestore-data
            print("HealthKit weight error (using Firestore only): \(error.localizedDescription)")
        }

        allWeights.sort { $0.date < $1.date }

        // Beräkna normaliserade värden
        if !allWeights.isEmpty {
            let minWeight = allWeights.map(\.value).min() ?? 0
            let maxWeight = allWeights.map(\.value).max() ?? 100
            let range = max(maxWeight - minWeight, 1)

            weightData = allWeights.map { point in
                let normalized = ((point.value - minWeight) / range) * 80 + 10 // 10-90 range
                return WeightDataPoint(date: point.date, weight: point.value, normalizedValue: normalized)
            }

            currentWeight = allWeights.last?.value
            previousWeight = allWeights.count > 1 ? allWeights[allWeights.count - 2].value : nil
            latestWeightDate = allWeights.last?.date
        } else {
            weightData = []
            currentWeight = measurementService.latestWeight
            previousWeight = nil
            latestWeightDate = nil
        }

    }
}

// WeightDataPoint and TimePeriod are defined in BiologyView.swift

#Preview {
    WeightChartView(
        measurementService: BodyMeasurementService(),
        healthKitService: HealthKitService()
    )
}
