import SwiftUI
import Charts

struct ActivityDetailView: View {
    let activityData: ActivityData
    let historicalData: [ActivityData]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Activity Score Ring
                activityScoreCard

                // Key Metrics Grid
                metricsGrid

                // Today's Workouts
                if !activityData.workouts.isEmpty {
                    workoutsCard
                }

                // Steps Trend
                stepsTrendCard

                // Calories Breakdown
                caloriesBreakdownCard
            }
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
        .clipped()
        .contentShape(Rectangle())
        .background(Color.vitalyBackground)
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Activity Score Card
    private var activityScoreCard: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background circles
                Circle()
                    .stroke(Color.vitalySurface, lineWidth: 20)
                    .frame(width: 180, height: 180)

                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(activityData.activityScore) / 100)
                    .stroke(
                        LinearGradient.vitalyActivityGradient,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.vitalyActivity.opacity(0.4), radius: 10, x: 0, y: 5)

                VStack(spacing: 4) {
                    Text("\(activityData.activityScore)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.vitalyTextPrimary)

                    Text("Aktivitetspoäng")
                        .font(.caption)
                        .foregroundColor(.vitalyTextSecondary)
                }
            }

            HStack(spacing: 4) {
                Image(systemName: activityScoreIcon)
                    .foregroundColor(activityScoreColor)
                Text(activityScoreText)
                    .font(.subheadline)
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

    private var activityScoreIcon: String {
        switch activityData.activityScore {
        case 80...: return "flame.fill"
        case 60..<80: return "checkmark.circle.fill"
        case 40..<60: return "hand.thumbsup.fill"
        default: return "tortoise.fill"
        }
    }

    private var activityScoreColor: Color {
        switch activityData.activityScore {
        case 80...: return .vitalyExcellent
        case 60..<80: return .vitalyGood
        case 40..<60: return .vitalyFair
        default: return .vitalyTextSecondary
        }
    }

    private var activityScoreText: String {
        switch activityData.activityScore {
        case 80...: return "Fantastisk aktivitetsdag!"
        case 60..<80: return "Bra aktivitetsnivå"
        case 40..<60: return "Måttlig aktivitet"
        default: return "Låg aktivitet"
        }
    }

    // MARK: - Metrics Grid
    private var metricsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                metricCard(
                    title: "Steg",
                    value: "\(activityData.steps.formatted())",
                    subtitle: "av 10,000",
                    icon: "figure.walk",
                    color: .vitalyExcellent,
                    progress: Double(activityData.steps) / 10000.0
                )

                metricCard(
                    title: "Kalorier",
                    value: "\(Int(activityData.activeCalories))",
                    subtitle: "aktiva kcal",
                    icon: "flame.fill",
                    color: .vitalyActivity,
                    progress: activityData.activeCalories / 600.0
                )
            }

            HStack(spacing: 12) {
                metricCard(
                    title: "Distans",
                    value: String(format: "%.1f", activityData.distanceKm),
                    subtitle: "kilometer",
                    icon: "location.fill",
                    color: Color(red: 0.4, green: 0.6, blue: 0.95),
                    progress: activityData.distanceKm / 8.0
                )

                metricCard(
                    title: "Träning",
                    value: "\(activityData.exerciseMinutes)",
                    subtitle: "minuter",
                    icon: "figure.run",
                    color: Color(red: 0.75, green: 0.45, blue: 0.85),
                    progress: Double(activityData.exerciseMinutes) / 30.0
                )
            }
        }
    }

    private func metricCard(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        color: Color,
        progress: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.vitalyTextPrimary)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.vitalyTextPrimary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.vitalyTextSecondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.vitalySurface)
                        .frame(height: 4)
                        .cornerRadius(2)

                    Rectangle()
                        .fill(color)
                        .frame(width: min(geometry.size.width * CGFloat(progress), geometry.size.width), height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
        )
    }

    // MARK: - Workouts Card
    private var workoutsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.run.circle.fill")
                    .font(.title3)
                    .foregroundColor(.vitalyActivity)

                Text("Dagens träningspass")
                    .font(.headline)
                    .foregroundColor(.vitalyTextPrimary)

                Spacer()

                Text("\(activityData.workouts.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.vitalyTextPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.vitalyActivity)
                    )
            }

            VStack(spacing: 12) {
                ForEach(activityData.workouts) { workout in
                    workoutRow(workout)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
        )
    }

    private func workoutRow(_ workout: WorkoutSummary) -> some View {
        HStack(spacing: 16) {
            // Workout icon
            ZStack {
                Circle()
                    .fill(workoutColor(workout.workoutType).opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: workoutIcon(workout.workoutType))
                    .font(.system(size: 18))
                    .foregroundColor(workoutColor(workout.workoutType))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutType)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.vitalyTextPrimary)

                HStack(spacing: 12) {
                    Label(workout.formattedDuration, systemImage: "clock.fill")
                    Label("\(Int(workout.calories)) kcal", systemImage: "flame.fill")
                }
                .font(.caption)
                .foregroundColor(.vitalyTextSecondary)
            }

            Spacer()

            if let hr = workout.averageHeartRate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(hr))")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.vitalyHeart)
                    Text("bpm")
                        .font(.caption2)
                        .foregroundColor(.vitalyTextSecondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.vitalySurface)
        )
    }

    private func workoutIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "löpning": return "figure.run"
        case "cykling": return "bicycle"
        case "styrketräning": return "dumbbell.fill"
        case "yoga": return "figure.mind.and.body"
        case "promenad": return "figure.walk"
        default: return "figure.mixed.cardio"
        }
    }

    private func workoutColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "löpning": return Color(hex: "FF5722")
        case "cykling": return Color(hex: "2196F3")
        case "styrketräning": return Color(hex: "9C27B0")
        case "yoga": return Color(hex: "00BCD4")
        case "promenad": return Color(hex: "4CAF50")
        default: return .green
        }
    }

    // MARK: - Steps Trend Card
    private var stepsTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Stegtrend")
                    .font(.headline)
                    .foregroundColor(.vitalyTextPrimary)

                Spacer()

                Text("Mål: 10,000")
                    .font(.caption)
                    .foregroundColor(.vitalyTextSecondary)
            }

            Chart {
                // Goal line
                RuleMark(y: .value("Mål", 10000))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(Color.vitalyTextSecondary.opacity(0.3))

                ForEach(historicalData) { data in
                    LineMark(
                        x: .value("Dag", data.date, unit: .day),
                        y: .value("Steg", data.steps)
                    )
                    .foregroundStyle(LinearGradient.vitalyActivityGradient)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Dag", data.date, unit: .day),
                        y: .value("Steg", data.steps)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                Color.vitalyActivity.opacity(0.3),
                                Color.vitalyActivity.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
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
                        if let steps = value.as(Int.self) {
                            Text("\(steps / 1000)k")
                                .font(.caption2)
                                .foregroundColor(.vitalyTextSecondary)
                        }
                    }
                }
            }
            .frame(height: 180)

            // Weekly average
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.caption)
                    .foregroundColor(.vitalyActivity)

                Text("Veckosnitt: \(weeklyAverageSteps.formatted()) steg")
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

    private var weeklyAverageSteps: Int {
        let total = historicalData.reduce(0) { $0 + $1.steps }
        return total / historicalData.count
    }

    // MARK: - Calories Breakdown Card
    private var caloriesBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kalorier")
                .font(.headline)
                .foregroundColor(.vitalyTextPrimary)

            // Total calories with breakdown
            VStack(spacing: 16) {
                HStack(alignment: .bottom, spacing: 8) {
                    Text("\(Int(activityData.totalCalories))")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.vitalyTextPrimary)

                    Text("totalt kcal")
                        .font(.subheadline)
                        .foregroundColor(.vitalyTextSecondary)
                        .padding(.bottom, 8)

                    Spacer()
                }

                // Breakdown bars
                VStack(spacing: 12) {
                    calorieBreakdownRow(
                        label: "Aktiva kalorier",
                        value: Int(activityData.activeCalories),
                        total: Int(activityData.totalCalories),
                        color: .vitalyActivity
                    )

                    calorieBreakdownRow(
                        label: "Basmetabolism",
                        value: Int(activityData.totalCalories - activityData.activeCalories),
                        total: Int(activityData.totalCalories),
                        color: Color(red: 0.4, green: 0.6, blue: 0.95)
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
        )
    }

    private func calorieBreakdownRow(label: String, value: Int, total: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.vitalyTextPrimary)

                Spacer()

                Text("\(value) kcal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.vitalyTextPrimary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.vitalySurface)
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value) / CGFloat(total), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
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
        ActivityDetailView(
            activityData: ActivityData(
                id: "1",
                date: Date(),
                steps: 12543,
                activeCalories: 487,
                totalCalories: 2387,
                distance: 9407,
                exerciseMinutes: 45,
                standHours: 11,
                workouts: [
                    WorkoutSummary(
                        id: "1",
                        workoutType: "Löpning",
                        duration: 2700,
                        calories: 320,
                        startTime: Date(),
                        averageHeartRate: 152
                    ),
                    WorkoutSummary(
                        id: "2",
                        workoutType: "Styrketräning",
                        duration: 1800,
                        calories: 167,
                        startTime: Date(),
                        averageHeartRate: 118
                    )
                ]
            ),
            historicalData: (0..<7).map { dayOffset in
                ActivityData(
                    id: "\(dayOffset)",
                    date: Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!,
                    steps: Int.random(in: 6000...15000),
                    activeCalories: Double.random(in: 300...600),
                    totalCalories: 2200,
                    distance: 8000,
                    exerciseMinutes: Int.random(in: 20...60),
                    standHours: 10,
                    workouts: []
                )
            }
        )
    }
}
