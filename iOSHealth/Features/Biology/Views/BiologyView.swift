import SwiftUI
import Charts

// MARK: - Shared TimePeriod Enum

enum TimePeriod: String, CaseIterable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"

    var days: Int {
        switch self {
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 365
        }
    }
}

// MARK: - Data Models

struct WeightDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let normalizedValue: Double
}

struct WaistDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let waist: Double
}

// MARK: - BiologyView

struct BiologyView: View {
    @State private var viewModel = BiologyViewModel()
    @State private var showingBodyMeasurements = false
    @EnvironmentObject private var coordinator: AppCoordinator

    // Weight trend chart state
    @State private var selectedWeightPeriod: TimePeriod = .threeMonths
    @State private var weightTrendData: [WeightDataPoint] = []
    @State private var isLoadingWeightTrend = true
    @State private var weightTrendCurrent: Double?
    @State private var weightTrendPrevious: Double?
    @State private var weightTrendLatestDate: Date?

    // Waist trend chart state
    @State private var selectedWaistPeriod: TimePeriod = .threeMonths
    @State private var waistTrendData: [WaistDataPoint] = []
    @State private var isLoadingWaistTrend = true
    @State private var waistTrendCurrent: Double?
    @State private var waistTrendPrevious: Double?
    @State private var waistTrendLatestDate: Date?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Biology")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(Color.vitalyTextPrimary)

                            Text("Your body composition")
                                .font(.subheadline)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                        if viewModel.isLoading {
                            loadingView
                        } else {
                            // Current Measurements Header
                            currentMeasurementsCard

                            // AI Biology Summary Card
                            aiBiologySummaryCard

                            // Weight Trend (inline)
                            weightTrendSection

                            // Waist Trend (inline)
                            waistTrendSection

                            // BMI Card
                            bmiCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .clipped()
            .contentShape(Rectangle())
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingBodyMeasurements) {
                BodyMeasurementView(
                    measurementService: coordinator.bodyMeasurementService,
                    healthKitService: coordinator.healthKitService
                )
            }
            .task {
                viewModel.updateHeight(coordinator.authService.currentUser?.heightCm)
                await coordinator.bodyMeasurementService.fetchMeasurements(limit: 365)
                await loadWeightTrendData()
                await loadWaistTrendData()
                viewModel.firestoreWeight = weightTrendCurrent
                viewModel.firestoreWaist = waistTrendCurrent
                await viewModel.loadData()
            }
            .refreshable {
                viewModel.updateHeight(coordinator.authService.currentUser?.heightCm)
                await coordinator.bodyMeasurementService.fetchMeasurements(limit: 365)
                await loadWeightTrendData()
                await loadWaistTrendData()
                viewModel.firestoreWeight = weightTrendCurrent
                viewModel.firestoreWaist = waistTrendCurrent
                viewModel.hasLoadedAI = false
                await viewModel.loadData()
            }
            .onChange(of: showingBodyMeasurements) { _, isShowing in
                if !isShowing {
                    Task {
                        await coordinator.bodyMeasurementService.fetchMeasurements(limit: 365)
                        await loadWeightTrendData()
                        await loadWaistTrendData()
                    }
                }
            }
            .onChange(of: selectedWeightPeriod) { _, _ in
                Task {
                    await loadWeightTrendData()
                }
            }
            .onChange(of: selectedWaistPeriod) { _, _ in
                Task {
                    await loadWaistTrendData()
                }
            }
        }
    }

    // MARK: - Current Measurements Card
    private var currentMeasurementsCard: some View {
        Button {
            showingBodyMeasurements = true
        } label: {
            VitalyCard(cornerRadius: 20) {
                HStack(spacing: 0) {
                    // Weight
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "scalemass.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.vitalyActivity)
                            Text("Weight")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }

                        if let weight = weightTrendCurrent ?? viewModel.bodyMass {
                            Text(String(format: "%.1f", weight))
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.vitalyTextPrimary)
                            Text("kg")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        } else {
                            Text("--")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.vitalyTextSecondary)
                            Text("kg")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Divider
                    Rectangle()
                        .fill(Color.vitalySurface)
                        .frame(width: 1, height: 60)

                    // Waist
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.arms.open")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.vitalySleep)
                            Text("Waist")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }

                        if let waist = waistTrendCurrent {
                            Text(String(format: "%.0f", waist))
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.vitalyTextPrimary)
                            Text("cm")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        } else {
                            Text("--")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.vitalyTextSecondary)
                            Text("cm")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.vitalyPrimary)

            Text("Loading health data...")
                .font(.subheadline)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - AI Biology Summary Card
    private var aiBiologySummaryCard: some View {
        VitalyCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.vitalyHeart)

                    Text("AI BODY ANALYSIS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)

                    Spacer()

                    if viewModel.isLoadingAI {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .vitalyHeart))
                            .scaleEffect(0.7)
                    }
                }

                if viewModel.isLoadingAI {
                    Text("Analyzing your body data...")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.vitalyTextSecondary)
                } else if let summary = viewModel.aiSummary {
                    Text(summary)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .lineSpacing(5)
                } else {
                    Text("Add body data to get AI insights about your body composition and fitness.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
            .padding(18)
        }
    }

    // MARK: - Weight Trend Section (Inline)

    private var weightTrendSection: some View {
        VitalyCard(cornerRadius: 20) {
            VStack(spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.vitalyActivity.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.vitalyActivity)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weight Trend")
                            .font(.headline)
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Text("Track your weight over time")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }

                    Spacer()
                }

                // Period Picker
                weightPeriodPicker

                // Chart
                if isLoadingWeightTrend {
                    ProgressView()
                        .frame(height: 220)
                } else if weightTrendData.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.vitalyTextSecondary.opacity(0.5))

                        Text("No data for this period")
                            .font(.subheadline)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                    .frame(height: 220)
                } else {
                    weightTrendChart
                        .frame(height: 220)
                }

                // Legend
                HStack(spacing: 24) {
                    weightLegendItem(color: Color.vitalySleep, label: "Weight", isDashed: true)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .background(Color.vitalySurface)

                // Trend Analysis
                weightTrendAnalysis
            }
            .padding(20)
        }
    }

    private var weightPeriodPicker: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedWeightPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedWeightPeriod == period ? .white : Color.vitalyTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedWeightPeriod == period ? Color.vitalyPrimary : Color.clear)
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

    private var weightTrendChart: some View {
        Chart {
            ForEach(weightTrendData) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Weight", point.normalizedValue)
                )
                .foregroundStyle(Color.vitalySleep)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                .interpolationMethod(.catmullRom)
            }

            ForEach(weightTrendData) { point in
                PointMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Weight", point.normalizedValue)
                )
                .foregroundStyle(Color.vitalySleep)
                .symbolSize(40)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: weightXAxisStride)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.vitalySurface)
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formatWeightAxisDate(date))
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
                        Text(formatWeightYAxisValue(val))
                            .font(.caption2)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }
            }
        }
        .chartYScale(domain: 0...100)
    }

    private func weightLegendItem(color: Color, label: String, isDashed: Bool) -> some View {
        HStack(spacing: 8) {
            if isDashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
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

    private var weightTrendAnalysis: some View {
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
            weightTrendRow(
                title: "Previous weight",
                value: weightTrendPrevious.map { String(format: "%.1f kg", $0) } ?? "No data"
            )

            Divider()
                .background(Color.vitalySurface)

            // 30-day projection
            weightTrendRow(
                title: "30-day projection",
                value: calculateWeightProjection()
            )

            if let current = weightTrendCurrent, let previous = weightTrendPrevious {
                Divider()
                    .background(Color.vitalySurface)

                let change = current - previous
                weightTrendRow(
                    title: "Change",
                    value: String(format: "%+.1f kg", change),
                    valueColor: change < 0 ? .green : (change > 0 ? Color.vitalyPrimary : Color.vitalyTextSecondary)
                )
            }
        }
    }

    private func weightTrendRow(title: String, value: String, valueColor: Color = Color.vitalyTextPrimary) -> some View {
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

    // MARK: - Waist Trend Section (Inline)

    private var waistTrendSection: some View {
        VitalyCard(cornerRadius: 20) {
            VStack(spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.vitalySleep.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "figure.arms.open")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.vitalySleep)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Waist Trend")
                            .font(.headline)
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Text("Track your waist over time")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }

                    Spacer()
                }

                // Period Picker
                waistPeriodPicker

                // Chart
                if isLoadingWaistTrend {
                    ProgressView()
                        .frame(height: 220)
                } else if waistTrendData.isEmpty {
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
                    .frame(height: 220)
                } else {
                    waistTrendChart
                        .frame(height: 220)
                }

                Divider()
                    .background(Color.vitalySurface)

                // Trend Analysis
                waistTrendAnalysis

                Divider()
                    .background(Color.vitalySurface)

                // Health Risk
                waistHealthRisk
            }
            .padding(20)
        }
    }

    private var waistPeriodPicker: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedWaistPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedWaistPeriod == period ? .white : Color.vitalyTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedWaistPeriod == period ? Color.vitalySleep : Color.clear)
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

    private var waistTrendChart: some View {
        Chart {
            ForEach(waistTrendData) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Waist", point.waist)
                )
                .foregroundStyle(Color.vitalySleep)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
            }

            ForEach(waistTrendData) { point in
                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Waist", point.waist)
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

            ForEach(waistTrendData) { point in
                PointMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Waist", point.waist)
                )
                .foregroundStyle(Color.vitalySleep)
                .symbolSize(50)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: waistXAxisStride)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.vitalySurface)
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formatWaistAxisDate(date))
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

    private var waistTrendAnalysis: some View {
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
            if let first = waistTrendData.first, let last = waistTrendData.last, waistTrendData.count > 1 {
                let change = last.waist - first.waist
                waistTrendRow(
                    title: "Total change",
                    value: String(format: "%+.0f cm", change),
                    valueColor: change < 0 ? .vitalyExcellent : (change > 0 ? Color.vitalyHeart : Color.vitalyTextSecondary)
                )

                Divider()
                    .background(Color.vitalySurface)
            }

            // Weekly average
            waistTrendRow(
                title: "Weekly average",
                value: calculateWaistWeeklyAverage()
            )

            Divider()
                .background(Color.vitalySurface)

            // 30-day projection
            waistTrendRow(
                title: "30-day projection",
                value: calculateWaistProjection()
            )
        }
    }

    private var waistHealthRisk: some View {
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

            if let waist = waistTrendCurrent {
                let riskLevel = calculateWaistRiskLevel(waist: waist)

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

                Divider()
                    .background(Color.vitalySurface)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Reference values (men/women)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.vitalyTextSecondary)

                    HStack(spacing: 16) {
                        waistReferenceItem(label: "Low risk", value: "< 94 / 80 cm", color: .vitalyExcellent)
                        waistReferenceItem(label: "High risk", value: "> 102 / 88 cm", color: .vitalyHeart)
                    }
                }
            } else {
                Text("Add waist measurements to see your health risk")
                    .font(.subheadline)
                    .foregroundStyle(Color.vitalyTextSecondary)
            }
        }
    }

    private func waistTrendRow(title: String, value: String, valueColor: Color = Color.vitalyTextPrimary) -> some View {
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

    private func waistReferenceItem(label: String, value: String, color: Color) -> some View {
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

    // MARK: - BMI Card
    private var bmiCard: some View {
        VitalyCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BMI")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.vitalyTextSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            if let bmi = calculateBMI() {
                                Text(String(format: "%.1f", bmi))
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.vitalyTextPrimary)
                            } else {
                                Text("--")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.vitalyTextSecondary)
                            }

                            Text("kg/m\u{00B2}")
                                .font(.subheadline)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }
                    }

                    Spacer()

                    // Status Badge
                    if let bmi = calculateBMI() {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(bmiStatus(for: bmi).color)
                                .frame(width: 8, height: 8)

                            Text(bmiStatus(for: bmi).label)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(bmiStatus(for: bmi).color)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(bmiStatus(for: bmi).color.opacity(0.15))
                        )
                    }
                }

                // BMI Scale Visualization
                if let bmi = calculateBMI() {
                    VStack(spacing: 12) {
                        // BMI Scale bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background gradient
                                HStack(spacing: 0) {
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: geometry.size.width * 0.25)
                                    Rectangle()
                                        .fill(Color.green)
                                        .frame(width: geometry.size.width * 0.25)
                                    Rectangle()
                                        .fill(Color.yellow)
                                        .frame(width: geometry.size.width * 0.25)
                                    Rectangle()
                                        .fill(Color.red)
                                        .frame(width: geometry.size.width * 0.25)
                                }
                                .cornerRadius(4)

                                // Indicator
                                let position = bmiPosition(for: bmi, width: geometry.size.width)
                                VStack(spacing: 2) {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 12, height: 12)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.vitalyTextPrimary, lineWidth: 2)
                                        )

                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: 2, height: 8)
                                }
                                .offset(x: position - 6)
                            }
                        }
                        .frame(height: 8)

                        // Labels
                        HStack {
                            Text("Underweight")
                                .font(.caption2)
                                .foregroundStyle(Color.vitalyTextSecondary)
                            Spacer()
                            Text("Normal")
                                .font(.caption2)
                                .foregroundStyle(Color.vitalyTextSecondary)
                            Spacer()
                            Text("Overweight")
                                .font(.caption2)
                                .foregroundStyle(Color.vitalyTextSecondary)
                            Spacer()
                            Text("Obese")
                                .font(.caption2)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }
                    }
                } else {
                    noDataPlaceholder
                }

                // Info text
                if let bmi = calculateBMI() {
                    Text(bmiInfoText(for: bmi))
                        .font(.caption)
                        .foregroundStyle(Color.vitalyTextSecondary)
                } else {
                    Text("Add weight and height to calculate your BMI.")
                        .font(.caption)
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Helper Functions

    /// Loads weight trend data for the inline chart
    private func loadWeightTrendData() async {
        isLoadingWeightTrend = true
        defer { isLoadingWeightTrend = false }

        let days = selectedWeightPeriod.days
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        // Firestore weights within the period
        let firestoreWeights = coordinator.bodyMeasurementService.measurements
            .filter { $0.weight != nil && $0.date >= cutoffDate }
            .map { DailyValue(date: $0.date, value: $0.weight!) }

        var allWeights: [DailyValue] = firestoreWeights

        // HealthKit weights - fill gaps
        do {
            let healthKitWeights = try await coordinator.healthKitService.fetchWeightHistory(for: days)
            for hk in healthKitWeights where hk.value > 0 {
                if !allWeights.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: hk.date) }) {
                    allWeights.append(hk)
                }
            }
        } catch {
            // HealthKit not available - use Firestore only
        }

        allWeights.sort { $0.date < $1.date }

        // Calculate normalized values
        if !allWeights.isEmpty {
            let minWeight = allWeights.map(\.value).min() ?? 0
            let maxWeight = allWeights.map(\.value).max() ?? 100
            let range = max(maxWeight - minWeight, 1)

            weightTrendData = allWeights.map { point in
                let normalized = ((point.value - minWeight) / range) * 80 + 10 // 10-90 range
                return WeightDataPoint(date: point.date, weight: point.value, normalizedValue: normalized)
            }

            weightTrendCurrent = allWeights.last?.value
            weightTrendPrevious = allWeights.count > 1 ? allWeights[allWeights.count - 2].value : nil
            weightTrendLatestDate = allWeights.last?.date
        } else {
            weightTrendData = []
            weightTrendCurrent = coordinator.bodyMeasurementService.latestWeight
            weightTrendPrevious = nil
            weightTrendLatestDate = nil
        }
    }

    /// Loads waist trend data for the inline chart
    private func loadWaistTrendData() async {
        isLoadingWaistTrend = true
        defer { isLoadingWaistTrend = false }

        let days = selectedWaistPeriod.days
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let filteredMeasurements = coordinator.bodyMeasurementService.measurements
            .filter { $0.waistCircumference != nil && $0.date >= startDate }
            .sorted { $0.date < $1.date }

        waistTrendData = filteredMeasurements.map { measurement in
            WaistDataPoint(date: measurement.date, waist: measurement.waistCircumference!)
        }

        waistTrendCurrent = waistTrendData.last?.waist ?? coordinator.bodyMeasurementService.latestWaist
        waistTrendPrevious = waistTrendData.count > 1 ? waistTrendData[waistTrendData.count - 2].waist : nil
        waistTrendLatestDate = waistTrendData.last?.date
    }

    // Weight chart helpers
    private var weightXAxisStride: Calendar.Component {
        switch selectedWeightPeriod {
        case .oneMonth: return .weekOfYear
        case .threeMonths: return .month
        case .sixMonths: return .month
        case .oneYear: return .month
        }
    }

    private func formatWeightAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        switch selectedWeightPeriod {
        case .oneMonth:
            formatter.dateFormat = "d MMM"
        case .threeMonths, .sixMonths, .oneYear:
            formatter.dateFormat = "MMM"
        }
        return formatter.string(from: date)
    }

    private func formatWeightYAxisValue(_ value: Double) -> String {
        if !weightTrendData.isEmpty {
            let minWeight = weightTrendData.map(\.weight).min() ?? 0
            let maxWeight = weightTrendData.map(\.weight).max() ?? 100
            let range = maxWeight - minWeight
            let actualValue = minWeight + (value / 100.0 * range)
            return String(format: "%.0f", actualValue)
        }
        return ""
    }

    private func calculateWeightProjection() -> String {
        guard weightTrendData.count >= 2 else { return "No data" }

        let sortedData = weightTrendData.sorted { $0.date < $1.date }
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

    // Waist chart helpers
    private var waistXAxisStride: Calendar.Component {
        switch selectedWaistPeriod {
        case .oneMonth: return .weekOfYear
        case .threeMonths: return .month
        case .sixMonths: return .month
        case .oneYear: return .month
        }
    }

    private func formatWaistAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        switch selectedWaistPeriod {
        case .oneMonth:
            formatter.dateFormat = "d MMM"
        case .threeMonths, .sixMonths, .oneYear:
            formatter.dateFormat = "MMM"
        }
        return formatter.string(from: date)
    }

    private func calculateWaistWeeklyAverage() -> String {
        guard waistTrendData.count >= 2 else { return "No data" }

        let sortedData = waistTrendData.sorted { $0.date < $1.date }
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

    private func calculateWaistProjection() -> String {
        guard waistTrendData.count >= 2 else { return "No data" }

        let sortedData = waistTrendData.sorted { $0.date < $1.date }
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

    private func calculateWaistRiskLevel(waist: Double) -> (title: String, description: String, color: Color) {
        if waist < 94 {
            return ("Low risk", "Your waist measurement is within the healthy range.", .vitalyExcellent)
        } else if waist < 102 {
            return ("Elevated risk", "Your waist measurement indicates slightly elevated health risk.", .vitalyRecovery)
        } else {
            return ("High risk", "Your waist measurement indicates increased risk of cardiovascular disease.", .vitalyHeart)
        }
    }

    // BMI helpers
    private func calculateBMI() -> Double? {
        guard let weight = weightTrendCurrent ?? viewModel.bodyMass,
              let height = coordinator.authService.currentUser?.heightCm,
              height > 0 else {
            return nil
        }
        let heightInMeters = height / 100.0
        return weight / (heightInMeters * heightInMeters)
    }

    private func bmiStatus(for bmi: Double) -> (label: String, color: Color) {
        switch bmi {
        case ..<18.5:
            return ("Underweight", .blue)
        case 18.5..<25:
            return ("Normal", .green)
        case 25..<30:
            return ("Overweight", .yellow)
        default:
            return ("Obese", .red)
        }
    }

    private func bmiPosition(for bmi: Double, width: CGFloat) -> CGFloat {
        let minBMI = 15.0
        let maxBMI = 35.0
        let clampedBMI = min(max(bmi, minBMI), maxBMI)
        let normalized = (clampedBMI - minBMI) / (maxBMI - minBMI)
        return width * normalized
    }

    private func bmiInfoText(for bmi: Double) -> String {
        switch bmi {
        case ..<18.5:
            return "Your BMI is below normal weight. Consider consulting a doctor."
        case 18.5..<25:
            return "Your BMI is within the normal range for healthy weight."
        case 25..<30:
            return "Your BMI indicates overweight. Regular exercise and healthy diet can help."
        default:
            return "Your BMI indicates obesity. Consult a doctor for personalized advice."
        }
    }

    // MARK: - No Data Placeholder
    private var noDataPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.vitalySurface)
            .frame(height: 80)
            .overlay {
                Text("No data available")
                    .font(.caption)
                    .foregroundStyle(Color.vitalyTextSecondary)
            }
    }
}

// MARK: - Profile Edit Sheet

struct ProfileEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let authService: AuthService

    @State private var birthDate: Date
    @State private var heightCm: Double
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(authService: AuthService) {
        self.authService = authService
        let user = authService.currentUser
        _birthDate = State(initialValue: user?.birthDate ?? Calendar.current.date(byAdding: .year, value: -30, to: Date())!)
        _heightCm = State(initialValue: user?.heightCm ?? 170)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Birth Date Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Birth Date", systemImage: "birthday.cake.fill")
                                .font(.headline)
                                .foregroundStyle(Color.vitalyTextPrimary)

                            DatePicker(
                                "",
                                selection: $birthDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.vitalyCardBackground)
                            )
                        }

                        // Height Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Height", systemImage: "ruler.fill")
                                .font(.headline)
                                .foregroundStyle(Color.vitalyTextPrimary)

                            VStack(spacing: 16) {
                                Text("\(Int(heightCm)) cm")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.vitalyTextPrimary)

                                Slider(value: $heightCm, in: 100...250, step: 1)
                                    .tint(Color.vitalyPrimary)

                                HStack {
                                    Text("100 cm")
                                        .font(.caption)
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                    Spacer()
                                    Text("250 cm")
                                        .font(.caption)
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.vitalyCardBackground)
                            )
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.vitalyTextSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveProfile()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(Color.vitalyPrimary)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.vitalyPrimary)
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func saveProfile() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                try await authService.updateBirthDate(birthDate)
                try await authService.updateHeight(heightCm)
                dismiss()
            } catch {
                errorMessage = "Could not save: \(error.localizedDescription)"
            }
            isSaving = false
        }
    }
}

// MARK: - Preview
#Preview("Biology View") {
    BiologyView()
        .environmentObject(AppCoordinator())
}

#Preview("Dark Mode") {
    BiologyView()
        .environmentObject(AppCoordinator())
        .preferredColorScheme(.dark)
}
