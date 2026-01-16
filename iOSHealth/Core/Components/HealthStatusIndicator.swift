import SwiftUI

// MARK: - Health Status Indicator

/// En liten indikator som visar hälsostatus med färg
struct HealthStatusIndicator: View {
    let evaluation: MetricEvaluation

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(evaluation.color)
                .frame(width: 8, height: 8)

            Text(evaluation.label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(evaluation.color)
        }
    }
}

// MARK: - Health Status Bar

/// En färgbar för att visa var på skalan ett värde ligger
struct HealthStatusBar: View {
    let evaluation: MetricEvaluation
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Bakgrund - gradient från rött till grönt
                LinearGradient(
                    colors: [
                        Color(hex: "E53935"),
                        Color(hex: "FB8C00"),
                        Color(hex: "FDD835"),
                        Color(hex: "7CB342"),
                        Color(hex: "43A047")
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(0.3)

                // Fylld del baserat på status
                LinearGradient(
                    colors: [
                        Color(hex: "E53935"),
                        Color(hex: "FB8C00"),
                        Color(hex: "FDD835"),
                        Color(hex: "7CB342"),
                        Color(hex: "43A047")
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(
                    Rectangle()
                        .frame(width: geometry.size.width * statusProgress)
                )

                // Markör för nuvarande position
                let markerSize = height + 4
                Circle()
                    .fill(evaluation.color)
                    .frame(width: markerSize, height: markerSize)
                    .shadow(color: evaluation.color.opacity(0.5), radius: 2)
                    .offset(x: (geometry.size.width * statusProgress) - (markerSize / 2))
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
    }

    private var statusProgress: Double {
        switch evaluation.status {
        case .veryPoor: return 0.1
        case .poor: return 0.3
        case .fair: return 0.5
        case .good: return 0.7
        case .excellent: return 0.9
        }
    }
}

// MARK: - Health Status Badge

/// En badge som visar status med ikon och färg
struct HealthStatusBadge: View {
    let evaluation: MetricEvaluation
    var showLabel: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: evaluation.status.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(evaluation.color)

            if showLabel {
                Text(evaluation.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(evaluation.color)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(evaluation.color.opacity(0.15))
        )
    }
}

// MARK: - Health Status Card Overlay

/// En overlay för kort som visar statusfärg på kanten
struct HealthStatusCardOverlay: View {
    let evaluation: MetricEvaluation
    var position: Edge = .leading
    var thickness: CGFloat = 3

    var body: some View {
        GeometryReader { geometry in
            switch position {
            case .leading:
                Rectangle()
                    .fill(evaluation.color)
                    .frame(width: thickness)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 16,
                            bottomLeadingRadius: 16
                        )
                    )
            case .trailing:
                Rectangle()
                    .fill(evaluation.color)
                    .frame(width: thickness)
                    .offset(x: geometry.size.width - thickness)
                    .clipShape(
                        UnevenRoundedRectangle(
                            bottomTrailingRadius: 16,
                            topTrailingRadius: 16
                        )
                    )
            case .top:
                Rectangle()
                    .fill(evaluation.color)
                    .frame(height: thickness)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 16,
                            topTrailingRadius: 16
                        )
                    )
            case .bottom:
                Rectangle()
                    .fill(evaluation.color)
                    .frame(height: thickness)
                    .offset(y: geometry.size.height - thickness)
                    .clipShape(
                        UnevenRoundedRectangle(
                            bottomLeadingRadius: 16,
                            bottomTrailingRadius: 16
                        )
                    )
            }
        }
    }
}

// MARK: - Preview

private struct HealthStatusPreview: View {
    static let excellent = MetricEvaluation(
        status: .excellent,
        label: "Excellent",
        comment: "Outstanding!",
        color: .green,
        percentile: 90
    )

    static let fair = MetricEvaluation(
        status: .fair,
        label: "Fair",
        comment: "Could be improved",
        color: .yellow,
        percentile: 50
    )

    static let veryPoor = MetricEvaluation(
        status: .veryPoor,
        label: "Very Poor",
        comment: "Critical",
        color: .red,
        percentile: 10
    )

    var body: some View {
        VStack(spacing: 20) {
            HealthStatusIndicator(evaluation: Self.excellent)
            HealthStatusIndicator(evaluation: Self.fair)
            HealthStatusIndicator(evaluation: Self.veryPoor)

            Divider()

            HealthStatusBar(evaluation: Self.excellent)
                .frame(width: 200)
            HealthStatusBar(evaluation: Self.fair)
                .frame(width: 200)
            HealthStatusBar(evaluation: Self.veryPoor)
                .frame(width: 200)

            Divider()

            HealthStatusBadge(evaluation: Self.excellent)
            HealthStatusBadge(evaluation: Self.veryPoor)
        }
        .padding()
        .background(Color.vitalyBackground)
        .preferredColorScheme(.dark)
    }
}

#Preview("Status Indicators") {
    HealthStatusPreview()
}
