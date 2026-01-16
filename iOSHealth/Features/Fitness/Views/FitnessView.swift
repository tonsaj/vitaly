import SwiftUI
import Charts

struct FitnessView: View {
    @State private var viewModel = FitnessViewModel()
    @State private var selectedDay: ActivityDay?

    var body: some View {
        ZStack {
            Color.vitalyBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fitness")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Text("Last 30 days")
                            .font(.subheadline)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                    if viewModel.isLoading {
                        loadingView
                    } else {
                        // AI Fitness Summary
                        aiSummaryCard

                        // Activity Calendar
                        activityCalendarCard

                        // Activity Summary
                        activitySummaryCard

                        // Strain Performance
                        strainPerformanceCard

                        // Cardio Section
                        cardioSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollContentBackground(.hidden)
            .clipped()
            .contentShape(Rectangle())
        }
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.loadData()
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.vitalyPrimary)

            Text("Loading workout data...")
                .font(.subheadline)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - AI Summary Card
    private var aiSummaryCard: some View {
        VitalyCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.vitalyActivity)

                    Text("AI WORKOUT ANALYSIS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)

                    Spacer()

                    if viewModel.isLoadingAI {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .vitalyActivity))
                            .scaleEffect(0.7)
                    }
                }

                if viewModel.isLoadingAI {
                    Text("Analyzing your workout...")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.vitalyTextSecondary)
                } else if let summary = viewModel.aiSummary {
                    Text(summary)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .lineSpacing(5)
                }
            }
            .padding(18)
        }
    }

    // MARK: - Activity Calendar Card
    private var activityCalendarCard: some View {
        VStack(spacing: 12) {
            VitalyCard(cornerRadius: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    // Month headers
                    HStack(spacing: 0) {
                        Text(viewModel.previousMonthName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Spacer()

                        Text(viewModel.currentMonthName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Spacer()
                    }

                    // Calendar grid
                    ActivityCalendarGrid(activityDays: viewModel.activityDays, selectedDay: $selectedDay)

                    // Legend
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.vitalyExcellent.opacity(0.5))
                                .frame(width: 8, height: 8)
                            Text("1")
                                .font(.caption2)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }

                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.vitalyExcellent.opacity(0.75))
                                .frame(width: 8, height: 8)
                            Text("2")
                                .font(.caption2)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }

                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.vitalyExcellent)
                                .frame(width: 8, height: 8)
                            Text("3+")
                                .font(.caption2)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }

                        Text("workouts")
                            .font(.caption2)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }
                .padding(20)
            }

            // Selected day activities
            if let day = selectedDay {
                selectedDayCard(for: day)
            }
        }
    }

    // MARK: - Selected Day Card
    private func selectedDayCard(for day: ActivityDay) -> some View {
        VitalyCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(formatDate(day.date))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Spacer()

                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedDay = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }

                if let dayData = viewModel.getActivityData(for: day.date) {
                    // Summary
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Calories")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                            Text("\(Int(dayData.calories)) kcal")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.vitalyActivity)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Exercise")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                            Text("\(dayData.exerciseMinutes) min")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.vitalyTextPrimary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Steps")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                            Text("\(dayData.steps)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.vitalyTextPrimary)
                        }

                        Spacer()
                    }

                    // Workouts
                    if !dayData.workouts.isEmpty {
                        Divider()
                            .background(Color.vitalyTextSecondary.opacity(0.3))

                        Text("WORKOUTS")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.vitalyTextSecondary)
                            .tracking(1)

                        ForEach(dayData.workouts) { workout in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.vitalyActivity.opacity(0.15))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: workout.icon)
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color.vitalyActivity)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(workout.type)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.vitalyTextPrimary)

                                    HStack(spacing: 12) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                                .font(.caption2)
                                            Text(workout.formattedDuration)
                                                .font(.caption)
                                        }
                                        .foregroundStyle(Color.vitalyTextSecondary)

                                        HStack(spacing: 4) {
                                            Image(systemName: "flame")
                                                .font(.caption2)
                                            Text("\(Int(workout.calories)) kcal")
                                                .font(.caption)
                                        }
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                    }
                                }

                                Spacer()
                            }
                        }
                    } else if dayData.exerciseMinutes == 0 && dayData.calories < 50 {
                        Text("No activity recorded")
                            .font(.subheadline)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                } else {
                    Text("No data for this day")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
            .padding(16)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date).capitalized
    }

    // MARK: - Activity Summary Card
    private var activitySummaryCard: some View {
        VitalyCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyActivity)

                    Text("Activity Summary")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.totalActivityTimeFormatted)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    HStack {
                        Text(viewModel.dateRangeText)
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "target")
                                .font(.caption2)
                            Text(viewModel.targetTimeFormatted)
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(Color.vitalyActivity)
                    }
                }

                // Activity trend chart
                if !viewModel.activityTrend.isEmpty {
                    ActivityTrendChart(data: viewModel.activityTrend)
                        .frame(height: 120)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Strain Performance Card
    private var strainPerformanceCard: some View {
        VitalyCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyRecovery)

                    Text("Strain Performance")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                }

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.strainPerformanceText)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Text(viewModel.strainStatus)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(viewModel.strainStatusColor)
                    }

                    Spacer()

                    // Strain wave chart
                    StrainWaveChart(data: viewModel.strainHistory)
                        .frame(width: 180, height: 80)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Cardio Section
    private var cardioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cardio")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.vitalyTextPrimary)
                .padding(.horizontal, 4)

            // Cardio Load Card
            cardioLoadCard

            // Two-column: Cardio Focus & HRR
            HStack(spacing: 12) {
                cardioFocusCard
                hrrCard
            }
        }
    }

    private var cardioLoadCard: some View {
        VitalyCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalySleep)

                    Text("Cardio Load")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                }

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.cardioLoad)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Text(viewModel.cardioLoadStatus)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.vitalyExcellent)
                    }

                    Spacer()

                    // Cardio load chart
                    CardioLoadChart(data: viewModel.cardioLoadHistory)
                        .frame(width: 180, height: 80)
                }
            }
            .padding(20)
        }
    }

    private var cardioFocusCard: some View {
        VitalyCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.caption)
                        .foregroundStyle(Color.vitalyExcellent)

                    Text("Cardio Focus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.cardioFocusType)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Text("\(viewModel.cardioFocusPercent) %")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.vitalyExcellent)
                }

                // Focus bars
                VStack(spacing: 6) {
                    FocusBar(label: "Low Aerobic", value: viewModel.lowAerobicPercent, color: .vitalyExcellent)
                    FocusBar(label: "High Aerobic", value: viewModel.highAerobicPercent, color: .blue)
                    FocusBar(label: "Anaerobic", value: viewModel.anaerobicPercent, color: .vitalyHeart)
                }
            }
            .padding(16)
        }
    }

    private var hrrCard: some View {
        VitalyCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "heart.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.vitalyHeart)

                    Text("HRR")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(viewModel.heartRateRecovery)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Text("bpm")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }

                    Text(viewModel.hrrStatus)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.vitalyExcellent)
                }

                // HRR mini chart
                HRRMiniChart(data: viewModel.hrrHistory)
                    .frame(height: 50)
            }
            .padding(16)
        }
    }

}

// MARK: - Activity Calendar Grid
struct ActivityCalendarGrid: View {
    let activityDays: [ActivityDay]
    @Binding var selectedDay: ActivityDay?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        VStack(spacing: 12) {
            if activityDays.isEmpty {
                Text("No workouts recorded in the last 42 days")
                    .font(.subheadline)
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .padding(.vertical, 20)
            } else {
                // Simple list of workout days
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(activityDays) { day in
                        VStack(spacing: 4) {
                            Text(formatDayOfMonth(day.date))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color.vitalyTextSecondary)

                            ActivityDayCell(day: day, isSelected: selectedDay?.id == day.id)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if selectedDay?.id == day.id {
                                            selectedDay = nil
                                        } else {
                                            selectedDay = day
                                        }
                                    }
                                }
                        }
                    }
                }
            }
        }
    }

    private func formatDayOfMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

struct ActivityDayCell: View {
    let day: ActivityDay
    var isSelected: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(cellColor)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if day.isToday {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.vitalyPrimary, lineWidth: 2)
                }
                if isSelected {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white, lineWidth: 2)
                }
            }
    }

    private var cellColor: Color {
        guard day.activityCount > 0 else {
            return Color.vitalySurface
        }

        switch day.activityCount {
        case 1:
            return Color.vitalyExcellent.opacity(0.5)
        case 2:
            return Color.vitalyExcellent.opacity(0.75)
        default:
            return Color.vitalyExcellent
        }
    }
}

// MARK: - Activity Trend Chart
struct ActivityTrendChart: View {
    let data: [ActivityTrendPoint]

    var body: some View {
        Chart {
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Time", point.cumulativeMinutes)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .interpolationMethod(.stepEnd)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Time", point.cumulativeMinutes)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.3), Color.red.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.stepEnd)
            }

            // Target line
            if let target = data.last?.target {
                RuleMark(y: .value("Target", target))
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    .foregroundStyle(Color.vitalyTextSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { _ in
                AxisValueLabel()
                    .foregroundStyle(Color.vitalyTextSecondary)
            }
        }
    }
}

// MARK: - Strain Wave Chart
struct StrainWaveChart: View {
    let data: [Double]

    var body: some View {
        GeometryReader { geometry in
            let maxValue = max(data.max() ?? 1, 1)
            let points = data.enumerated().map { index, value in
                CGPoint(
                    x: geometry.size.width * CGFloat(index) / CGFloat(max(data.count - 1, 1)),
                    y: geometry.size.height * (1 - CGFloat(value) / CGFloat(maxValue))
                )
            }

            ZStack {
                // Fill area
                Path { path in
                    guard points.count > 1 else { return }
                    path.move(to: CGPoint(x: 0, y: geometry.size.height))
                    for point in points {
                        path.addLine(to: point)
                    }
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.vitalyExcellent.opacity(0.3), Color.vitalyExcellent.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Line
                Path { path in
                    guard points.count > 1 else { return }
                    path.move(to: points[0])
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )

                // End point
                if let lastPoint = points.last {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .position(lastPoint)
                }
            }
        }
    }
}

// MARK: - Cardio Load Chart
struct CardioLoadChart: View {
    let data: [Double]

    var body: some View {
        GeometryReader { geometry in
            let maxValue = max(data.max() ?? 1, 1)
            let points = data.enumerated().map { index, value in
                CGPoint(
                    x: geometry.size.width * CGFloat(index) / CGFloat(max(data.count - 1, 1)),
                    y: geometry.size.height * (1 - CGFloat(value) / CGFloat(maxValue))
                )
            }

            ZStack {
                // Fill area
                Path { path in
                    guard points.count > 1 else { return }
                    path.move(to: CGPoint(x: 0, y: geometry.size.height))
                    for point in points {
                        path.addLine(to: point)
                    }
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Color.vitalySleep.opacity(0.3), Color.vitalySleep.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Line
                Path { path in
                    guard points.count > 1 else { return }
                    path.move(to: points[0])
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(Color.vitalySleep, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                // End point
                if let lastPoint = points.last {
                    Circle()
                        .fill(Color.vitalyExcellent)
                        .frame(width: 8, height: 8)
                        .position(lastPoint)
                }
            }
        }
    }
}

// MARK: - Focus Bar
struct FocusBar: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.vitalySurface)
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(value) / 100, height: 6)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - HRR Mini Chart
struct HRRMiniChart: View {
    let data: [Double]

    var body: some View {
        GeometryReader { geometry in
            let maxValue = max(data.max() ?? 1, 1)
            let minValue = data.min() ?? 0
            let range = maxValue - minValue

            ZStack {
                // Line
                Path { path in
                    guard data.count > 1 else { return }

                    for (index, value) in data.enumerated() {
                        let x = geometry.size.width * CGFloat(index) / CGFloat(data.count - 1)
                        let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
                        let y = geometry.size.height * (1 - CGFloat(normalizedValue))

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [.pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )

                // End point
                if let lastValue = data.last {
                    let normalizedValue = range > 0 ? (lastValue - minValue) / range : 0.5
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 6, height: 6)
                        .position(
                            x: geometry.size.width,
                            y: geometry.size.height * (1 - CGFloat(normalizedValue))
                        )
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Fitness View") {
    FitnessView()
}

#Preview("Dark Mode") {
    FitnessView()
        .preferredColorScheme(.dark)
}
