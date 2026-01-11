import SwiftUI

struct StrainDetailEnhancedView: View {
    @Environment(\.dismiss) private var dismiss
    let activityData: ActivityData?
    @State private var animateRing = false
    @State private var showInsightExpanded = false

    private var strainPercentage: Double {
        guard let activity = activityData else { return 0 }
        return Double(activity.activityScore)
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.vitalyBackground,
                    Color(red: 0.08, green: 0.06, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Large Ring Gauge
                    largeRingGauge

                    // Stats Cards Row
                    statsCardsRow

                    // AI Coaching Insight
                    aiInsightCard

                    // Activity Timeline
                    if let workouts = activityData?.workouts, !workouts.isEmpty {
                        activityTimeline
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Belastning")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)
            }

            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.vitalyCardBackground)
                            .frame(width: 34, height: 34)

                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.vitalyTextPrimary)
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Info action
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.vitalyCardBackground)
                            .frame(width: 34, height: 34)

                        Image(systemName: "info")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.vitalyTextPrimary)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).delay(0.2)) {
                animateRing = true
            }
        }
    }

    // MARK: - Large Ring Gauge
    private var largeRingGauge: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.vitalyActivity.opacity(0.15), lineWidth: 24)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animateRing ? min(strainPercentage / 100, 1.0) : 0)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.vitalyActivity.opacity(0.6),
                                Color.vitalyActivity,
                                Color.vitalyActivity,
                                Color.vitalyActivity.opacity(0.8)
                            ],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.vitalyActivity.opacity(0.4), radius: 8, x: 0, y: 0)

                // Center content
                VStack(spacing: 8) {
                    Text("\(Int(strainPercentage))")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Text("Belastning")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
            .frame(width: 240, height: 240)

            // Status label
            HStack(spacing: 8) {
                Circle()
                    .fill(strainColor)
                    .frame(width: 8, height: 8)

                Text(strainLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(strainColor)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(strainColor.opacity(0.15))
            )
        }
        .padding(.vertical, 20)
    }

    // MARK: - Stats Cards Row
    private var statsCardsRow: some View {
        HStack(spacing: 12) {
            // Duration Card
            StatCard(
                icon: "clock.fill",
                label: "Varaktighet",
                value: "\(activityData?.exerciseMinutes ?? 0)",
                unit: "min",
                color: Color.vitalyActivity
            )

            // Total Energy Card
            StatCard(
                icon: "flame.fill",
                label: "Total energi",
                value: String(format: "%.0f", activityData?.activeCalories ?? 0),
                unit: "kcal",
                color: Color.vitalyHeart
            )
        }
    }

    // MARK: - AI Insight Card
    private var aiInsightCard: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.vitalyPrimary)

                        Text("AI COACHING")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.vitalyTextSecondary)
                            .tracking(1.2)
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showInsightExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: showInsightExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }

                Text(aiInsightText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.vitalyTextPrimary)
                    .lineSpacing(6)
                    .lineLimit(showInsightExpanded ? nil : 3)

                if showInsightExpanded {
                    VStack(spacing: 12) {
                        Divider()
                            .background(Color.vitalySurface)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Rekommendation")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.vitalyTextSecondary)

                                Text("Ta det lugnare imorgon")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.vitalyTextPrimary)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.vitalyExcellent)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
            }
            .padding(20)
        }
    }

    // MARK: - Activity Timeline
    private var activityTimeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TIDSLINJE")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.vitalyTextSecondary)
                .tracking(1.2)

            VStack(spacing: 0) {
                ForEach(activityData?.workouts ?? []) { workout in
                    ActivityTimelineDetailRow(workout: workout)

                    if workout.id != activityData?.workouts.last?.id {
                        Divider()
                            .background(Color.vitalySurface)
                            .padding(.leading, 70)
                    }
                }
            }
            .background(Color.vitalyCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }

    // MARK: - Computed Properties
    private var strainColor: Color {
        switch strainPercentage {
        case 0..<40: return Color.vitalyExcellent
        case 40..<70: return Color.vitalyActivity
        case 70..<90: return Color.vitalyFair
        default: return Color.vitalyHeart
        }
    }

    private var strainLabel: String {
        switch strainPercentage {
        case 0..<40: return "Låg belastning"
        case 40..<70: return "Måttlig belastning"
        case 70..<90: return "Hög belastning"
        default: return "Maximal belastning"
        }
    }

    private var aiInsightText: String {
        let score = Int(strainPercentage)
        if score >= 80 {
            return "Du har haft en mycket intensiv dag med hög belastning. Din kropp behöver optimal återhämtning. Prioritera sömn och hydration ikväll för bästa resultat imorgon."
        } else if score >= 60 {
            return "Bra aktivitetsnivå idag! Du utmanar din kropp lagom mycket. Fortsätt i denna takt men glöm inte vikten av återhämtning mellan intensiva dagar."
        } else if score >= 30 {
            return "Måttlig aktivitet idag. Det är okej att ha lättare dagar - din kropp behöver variation. Imorgon kan du utmana dig lite mer om du känner dig redo."
        } else {
            return "Låg aktivitetsnivå idag. Om detta var planerad återhämtning är det perfekt! Annars, försök lägga in lite rörelse även på lättare dagar."
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VitalyCard {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(color)
                }

                VStack(spacing: 4) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(Color.vitalyTextSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(value)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Activity Timeline Detail Row
struct ActivityTimelineDetailRow: View {
    let workout: WorkoutSummary

    var body: some View {
        HStack(spacing: 16) {
            // Time indicator
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedTime)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(Color.vitalyTextSecondary)
            }
            .frame(width: 50)

            // Activity icon
            ZStack {
                Circle()
                    .fill(workoutColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: workoutIcon)
                    .font(.system(size: 24))
                    .foregroundStyle(workoutColor)
            }

            // Activity details
            VStack(alignment: .leading, spacing: 6) {
                Text(workout.workoutType)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text(workout.formattedDuration)
                            .font(.caption)
                    }
                    .foregroundStyle(Color.vitalyTextSecondary)

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                        Text(String(format: "%.0f kcal", workout.calories))
                            .font(.caption)
                    }
                    .foregroundStyle(Color.vitalyTextSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var workoutIcon: String {
        switch workout.workoutType.lowercased() {
        case "löpning": return "figure.run"
        case "promenad": return "figure.walk"
        case "cykling": return "figure.outdoor.cycle"
        case "simning": return "figure.pool.swim"
        case "yoga": return "figure.yoga"
        case "styrketräning": return "dumbbell.fill"
        case "hiit": return "flame.fill"
        default: return "figure.mixed.cardio"
        }
    }

    private var workoutColor: Color {
        switch workout.workoutType.lowercased() {
        case "löpning": return .vitalyActivity
        case "promenad": return .vitalyExcellent
        case "cykling": return .vitalyRecovery
        case "simning": return .vitalySleep
        case "styrketräning": return .vitalyHeart
        default: return .vitalyPrimary
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: workout.startTime)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter.string(from: workout.startTime)
    }
}

#Preview {
    NavigationStack {
        StrainDetailEnhancedView(activityData: ActivityData(
            id: "1",
            date: Date(),
            steps: 8500,
            activeCalories: 450,
            totalCalories: 2100,
            distance: 6500,
            exerciseMinutes: 45,
            standHours: 10,
            workouts: [
                WorkoutSummary(
                    id: "1",
                    workoutType: "Löpning",
                    duration: 1800,
                    calories: 250,
                    startTime: Date().addingTimeInterval(-3600),
                    averageHeartRate: 145
                ),
                WorkoutSummary(
                    id: "2",
                    workoutType: "Styrketräning",
                    duration: 2700,
                    calories: 200,
                    startTime: Date().addingTimeInterval(-7200),
                    averageHeartRate: 125
                )
            ]
        ))
    }
    .preferredColorScheme(.dark)
}
