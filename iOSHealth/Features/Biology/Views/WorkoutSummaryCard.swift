import SwiftUI

enum WorkoutType {
    case running
    case cycling
    case strength
    case swimming
    case walking
    case yoga
    case hiit
    case other

    var displayName: String {
        switch self {
        case .running: return "Löpning"
        case .cycling: return "Cykling"
        case .strength: return "Styrketräning"
        case .swimming: return "Simning"
        case .walking: return "Promenad"
        case .yoga: return "Yoga"
        case .hiit: return "HIIT"
        case .other: return "Träning"
        }
    }

    var color: Color {
        switch self {
        case .running: return Color.vitalyActivity
        case .cycling: return Color.vitalySleep
        case .strength: return Color.vitalyHeart
        case .swimming: return Color.blue
        case .walking: return Color.vitalyRecovery
        case .yoga: return Color.vitalySleep
        case .hiit: return Color.vitalyPrimary
        case .other: return Color.vitalyTextSecondary
        }
    }
}

struct WorkoutSummaryCard: View {
    let type: WorkoutType
    let duration: Int // minutes
    let calories: Int
    let icon: String

    var body: some View {
        VitalyCard(cornerRadius: 16) {
            HStack(spacing: 16) {
                // Icon with circular background
                ZStack {
                    Circle()
                        .fill(Color.vitalySurface)
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(type.color)
                }

                // Workout info
                VStack(alignment: .leading, spacing: 6) {
                    Text(type.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    HStack(spacing: 12) {
                        // Duration
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.vitalyTextSecondary)

                            Text("\(duration) min")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }

                        // Divider
                        Circle()
                            .fill(Color.vitalyTextSecondary.opacity(0.3))
                            .frame(width: 3, height: 3)

                        // Calories
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.vitalyActivity)

                            Text("\(calories) kcal")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.vitalyTextSecondary)
            }
            .padding(16)
        }
    }
}

// MARK: - Preview
#Preview("Workout Cards") {
    ZStack {
        Color.vitalyBackground.ignoresSafeArea()

        VStack(spacing: 12) {
            WorkoutSummaryCard(
                type: .running,
                duration: 45,
                calories: 420,
                icon: "figure.run"
            )

            WorkoutSummaryCard(
                type: .cycling,
                duration: 60,
                calories: 520,
                icon: "figure.outdoor.cycle"
            )

            WorkoutSummaryCard(
                type: .strength,
                duration: 35,
                calories: 280,
                icon: "dumbbell.fill"
            )
        }
        .padding()
    }
}

#Preview("Single Card") {
    ZStack {
        Color.vitalyBackground.ignoresSafeArea()

        WorkoutSummaryCard(
            type: .running,
            duration: 45,
            calories: 420,
            icon: "figure.run"
        )
        .padding()
    }
}
