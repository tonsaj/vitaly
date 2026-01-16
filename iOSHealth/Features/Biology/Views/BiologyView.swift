import SwiftUI
import Charts

struct BiologyView: View {
    @State private var viewModel = BiologyViewModel()
    @State private var showingBodyMeasurements = false
    @State private var showingWeightChart = false
    @State private var showingWaistChart = false
    @EnvironmentObject private var coordinator: AppCoordinator

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
                            // AI Biology Summary Card
                            aiBiologySummaryCard

                            // Weight Card with Chart
                            weightCard

                            // Charts Section (Weight & Waist Trends)
                            chartsSection

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
            .sheet(isPresented: $showingWeightChart) {
                WeightChartView(
                    measurementService: coordinator.bodyMeasurementService,
                    healthKitService: coordinator.healthKitService
                )
            }
            .sheet(isPresented: $showingWaistChart) {
                WaistChartView(measurementService: coordinator.bodyMeasurementService)
            }
            .task {
                // Update height from user profile
                viewModel.updateHeight(coordinator.authService.currentUser?.heightCm)
                await viewModel.loadData()
            }
            .refreshable {
                viewModel.updateHeight(coordinator.authService.currentUser?.heightCm)
                await viewModel.loadData()
            }
        }
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

    // MARK: - Charts Section
    private var chartsSection: some View {
        VStack(spacing: 12) {
            // Weight Chart Button
            Button {
                showingWeightChart = true
            } label: {
                VitalyCard(cornerRadius: 16) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.vitalyActivity.opacity(0.15))
                                .frame(width: 48, height: 48)

                            Image(systemName: "scalemass.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.vitalyActivity)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weight Trend")
                                .font(.headline)
                                .foregroundStyle(Color.vitalyTextPrimary)

                            Text("Track your weight over time")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                    .padding(16)
                }
            }
            .buttonStyle(.plain)

            // Waist Chart Button
            Button {
                showingWaistChart = true
            } label: {
                VitalyCard(cornerRadius: 16) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.vitalySleep.opacity(0.15))
                                .frame(width: 48, height: 48)

                            Image(systemName: "figure.arms.open")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.vitalySleep)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Waist Trend")
                                .font(.headline)
                                .foregroundStyle(Color.vitalyTextPrimary)

                            Text("Track your waist over time")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                    .padding(16)
                }
            }
            .buttonStyle(.plain)
        }
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

    // MARK: - Weight Card
    private var weightCard: some View {
        Button {
            showingBodyMeasurements = true
        } label: {
            VitalyCard(cornerRadius: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    // Header with trend indicator
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weight")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.vitalyTextSecondary)

                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                if let weight = viewModel.bodyMass ?? coordinator.bodyMeasurementService.latestWeight {
                                    Text(String(format: "%.1f", weight))
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.vitalyTextPrimary)
                                } else {
                                    Text("--")
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                }

                                Text("kg")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.vitalyTextSecondary)
                            }
                        }

                        Spacer()

                        // Trend indicator
                        if let trend = weightTrend {
                            HStack(spacing: 4) {
                                Image(systemName: trend < 0 ? "arrow.down.right" : "arrow.up.right")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(trend < 0 ? "Decreasing" : "Increasing")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(trend < 0 ? Color.green : Color.vitalyPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill((trend < 0 ? Color.green : Color.vitalyPrimary).opacity(0.15))
                            )
                        }
                    }

                    // Weight History Chart - Last 3 months with dots
                    let weightMeasurements = getWeightMeasurements()
                    if !weightMeasurements.isEmpty {
                        Chart {
                            ForEach(Array(weightMeasurements), id: \.date) { measurement in
                                // Dashed line
                                LineMark(
                                    x: .value("Date", measurement.date),
                                    y: .value("Weight", measurement.weight)
                                )
                                .foregroundStyle(Color.vitalySleep)
                                .interpolationMethod(.catmullRom)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))

                                // Point marks (dots)
                                PointMark(
                                    x: .value("Date", measurement.date),
                                    y: .value("Weight", measurement.weight)
                                )
                                .foregroundStyle(Color.vitalySleep)
                                .symbolSize(50)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month)) { value in
                                AxisValueLabel {
                                    if let date = value.as(Date.self) {
                                        Text(date, format: .dateTime.month(.abbreviated))
                                            .font(.caption2)
                                            .foregroundStyle(Color.vitalyTextSecondary)
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.vitalySurface)
                                AxisValueLabel {
                                    if let val = value.as(Double.self) {
                                        Text("\(Int(val))")
                                            .font(.caption2)
                                            .foregroundStyle(Color.vitalyTextSecondary)
                                    }
                                }
                            }
                        }
                        .frame(height: 120)
                    } else {
                        noDataPlaceholder
                    }

                    // Info text
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(Color.vitalyPrimary)
                        Text("Tap to add measurement")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }
                .padding(20)
            }
        }
        .buttonStyle(.plain)
    }

    private func getWeightMeasurements() -> [(date: Date, weight: Double)] {
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        return coordinator.bodyMeasurementService.measurements
            .filter { $0.date >= threeMonthsAgo }
            .compactMap { measurement -> (date: Date, weight: Double)? in
                guard let weight = measurement.weight else { return nil }
                return (measurement.date, weight)
            }
            .sorted { $0.date < $1.date }
    }

    private var weightTrend: Double? {
        let measurements = getWeightMeasurements()
        guard measurements.count >= 2 else { return nil }
        let first = measurements.first!.weight
        let last = measurements.last!.weight
        return last - first
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

                            Text("kg/m²")
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

    private func calculateBMI() -> Double? {
        guard let weight = viewModel.bodyMass ?? coordinator.bodyMeasurementService.latestWeight,
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
        // Map BMI to position on scale (15-35 range)
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
