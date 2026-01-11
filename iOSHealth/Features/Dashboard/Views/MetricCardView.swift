import SwiftUI

struct MetricCardView: View {
    let metricType: MetricType
    let mainValue: String
    let subtitle: String
    let trend: TrendIndicator?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VitalyCard {
                VStack(alignment: .leading, spacing: 16) {
                    // Header with icon
                    HStack {
                        // Sunburst icon for metric
                        ZStack {
                            Circle()
                                .fill(metricType.vitalyColor.opacity(0.15))
                                .frame(width: 50, height: 50)

                            Image(systemName: metricType.icon)
                                .font(.title3)
                                .foregroundStyle(metricType.vitalyColor)
                        }

                        Spacer()

                        if let trend = trend {
                            TrendBadge(trend: trend)
                        }
                    }

                    // Main value
                    VStack(alignment: .leading, spacing: 6) {
                        Text(mainValue)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }

                    // Footer with metric title
                    HStack {
                        Text(metricType.title.uppercased())
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                            .tracking(1)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(metricType.vitalyColor)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(CardButtonStyle())
    }
}

// MARK: - Trend Indicator
enum TrendIndicator {
    case up(String)
    case down(String)
    case neutral

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "minus"
        }
    }

    var color: Color {
        switch self {
        case .up: return .vitalyExcellent
        case .down: return .vitalyPoor
        case .neutral: return .vitalyTextSecondary
        }
    }

    var text: String? {
        switch self {
        case .up(let value), .down(let value):
            return value
        case .neutral:
            return nil
        }
    }
}

// MARK: - Trend Badge
struct TrendBadge: View {
    let trend: TrendIndicator

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon)
                .font(.caption2.weight(.semibold))

            if let text = trend.text {
                Text(text)
                    .font(.caption2.weight(.semibold))
            }
        }
        .foregroundStyle(trend.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(trend.color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(trend.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Card Button Style
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview("Sleep Card") {
    ZStack {
        Color.vitalyBackground.ignoresSafeArea()

        MetricCardView(
            metricType: .sleep,
            mainValue: "7h 32m",
            subtitle: "Utmärkt kvalitet",
            trend: .up("+15m"),
            action: {}
        )
        .padding()
    }
}

#Preview("Activity Card") {
    ZStack {
        Color.vitalyBackground.ignoresSafeArea()

        MetricCardView(
            metricType: .activity,
            mainValue: "8,542",
            subtitle: "85 poäng",
            trend: .down("-1,200"),
            action: {}
        )
        .padding()
    }
}

#Preview("All Metric Cards") {
    ZStack {
        Color.vitalyBackground.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 16) {
                MetricCardView(
                    metricType: .sleep,
                    mainValue: "7h 32m",
                    subtitle: "Utmärkt kvalitet",
                    trend: .up("+15m"),
                    action: {}
                )

                MetricCardView(
                    metricType: .activity,
                    mainValue: "8,542",
                    subtitle: "85 poäng",
                    trend: .neutral,
                    action: {}
                )

                MetricCardView(
                    metricType: .heart,
                    mainValue: "58 bpm",
                    subtitle: "Atletisk",
                    trend: .up("+2"),
                    action: {}
                )

                MetricCardView(
                    metricType: .recovery,
                    mainValue: "85%",
                    subtitle: "Redo för träning",
                    trend: .up("+5%"),
                    action: {}
                )
            }
            .padding()
        }
    }
}
