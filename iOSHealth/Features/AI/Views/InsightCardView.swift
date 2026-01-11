import SwiftUI

struct InsightCardView: View {
    let insight: AIInsight
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon with priority indicator
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(priorityGradient)
                            .frame(width: 56, height: 56)
                            .shadow(color: Color.vitalyPrimary.opacity(0.3), radius: 8, x: 0, y: 4)

                        Image(systemName: insight.type.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    if !insight.isRead {
                        Circle()
                            .fill(Color.vitalyAccent)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.vitalyCardBackground, lineWidth: 2)
                            )
                            .offset(x: 4, y: -4)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(insight.title)
                        .font(.headline)
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Text(contentPreview)
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary.opacity(0.7))

                        Text(formattedDate)
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary.opacity(0.7))

                        if !insight.metrics.isEmpty {
                            Circle()
                                .fill(Color.vitalyTextSecondary.opacity(0.5))
                                .frame(width: 3, height: 3)

                            HStack(spacing: 4) {
                                ForEach(insight.metrics.prefix(3), id: \.self) { metric in
                                    Image(systemName: metricIcon(for: metric))
                                        .font(.caption2)
                                        .foregroundStyle(metricColor(for: metric))
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextSecondary.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.vitalyCardBackground)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed Properties

    private var priorityGradient: LinearGradient {
        switch insight.priority {
        case .high:
            return LinearGradient(
                colors: [Color.vitalyPrimary, Color.vitalyHeart],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .normal:
            return LinearGradient(
                colors: [Color.vitalyPrimary, Color.vitalySecondary, Color.vitalyTertiary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .low:
            return LinearGradient(
                colors: [Color.vitalyTextSecondary, Color.vitalyTextSecondary.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var contentPreview: String {
        let maxLength = 100
        if insight.content.count > maxLength {
            let index = insight.content.index(insight.content.startIndex, offsetBy: maxLength)
            return String(insight.content[..<index]) + "..."
        }
        return insight.content
    }

    private var formattedDate: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(insight.createdAt) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Idag, " + formatter.string(from: insight.createdAt)
        } else if calendar.isDateInYesterday(insight.createdAt) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Igår, " + formatter.string(from: insight.createdAt)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatter.locale = Locale(identifier: "sv_SE")
            return formatter.string(from: insight.createdAt)
        }
    }

    private func metricIcon(for metric: String) -> String {
        switch metric {
        case "sleep": return "moon.fill"
        case "activity": return "figure.run"
        case "heart": return "heart.fill"
        case "recovery": return "battery.100.bolt"
        default: return "chart.bar.fill"
        }
    }

    private func metricColor(for metric: String) -> Color {
        switch metric {
        case "sleep": return .vitalySleep
        case "activity": return .vitalyActivity
        case "heart": return .vitalyHeart
        case "recovery": return .vitalyRecovery
        default: return .vitalyTextSecondary
        }
    }
}

#Preview("Normal Priority - Read") {
    InsightCardView(
        insight: AIInsight(
            id: "1",
            type: .dailySummary,
            title: "Daglig sammanfattning",
            content: "Du har haft en bra dag med 8 timmar sömn och 10,000 steg. Din vilopuls är stabil på 62 bpm. Fortsätt så här!",
            metrics: ["sleep", "activity", "heart"],
            createdAt: Date(),
            isRead: true,
            priority: .normal
        ),
        onTap: {}
    )
    .padding()
}

#Preview("High Priority - Unread") {
    InsightCardView(
        insight: AIInsight(
            id: "2",
            type: .sleepAnalysis,
            title: "Sömnanalys",
            content: "Din sömnkvalitet har varit låg de senaste tre dagarna. Du får för lite djupsömn och REM-sömn. Försök att gå och lägga dig tidigare och undvik skärmar innan läggdags.",
            metrics: ["sleep"],
            createdAt: Date().addingTimeInterval(-3600),
            isRead: false,
            priority: .high
        ),
        onTap: {}
    )
    .padding()
}

#Preview("Low Priority") {
    InsightCardView(
        insight: AIInsight(
            id: "3",
            type: .activityTrend,
            title: "Aktivitetstrend",
            content: "Din aktivitetsnivå är stabil. Du har i genomsnitt gått 9,500 steg per dag under den senaste veckan.",
            metrics: ["activity"],
            createdAt: Date().addingTimeInterval(-86400),
            isRead: true,
            priority: .low
        ),
        onTap: {}
    )
    .padding()
}
