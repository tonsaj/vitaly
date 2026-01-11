import SwiftUI

struct InsightDetailView: View {
    let insight: AIInsight
    let onAppear: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Gradient Header
                        gradientHeader

                        // Content Card
                        VStack(alignment: .leading, spacing: 24) {
                            contentSection

                            if !insight.metrics.isEmpty {
                                Divider()
                                    .background(Color.vitalyTextSecondary.opacity(0.2))

                                metricsSection
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.vitalyCardBackground)
                        )
                        .padding(.horizontal)
                        .padding(.top, -30)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(insight.type.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.vitalyCardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Stäng") {
                        dismiss()
                    }
                    .foregroundStyle(Color.vitalyTextPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.vitalyPrimary)
                    }
                }
            }
            .onAppear {
                onAppear()
            }
        }
    }

    // MARK: - Gradient Header

    private var gradientHeader: some View {
        ZStack(alignment: .bottom) {
            // Gradient Background
            Rectangle()
                .fill(priorityGradient)
                .frame(height: 200)
                .overlay(
                    LinearGradient(
                        colors: [.clear, Color.vitalyBackground.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Header Content
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 72, height: 72)
                        .blur(radius: 10)

                    Circle()
                        .fill(.white)
                        .frame(width: 64, height: 64)

                    Image(systemName: insight.type.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(priorityGradient)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(insight.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.caption)

                        Text(formattedDate)
                            .font(.caption)
                    }
                    .foregroundStyle(.white.opacity(0.9))

                    priorityBadge
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analys")
                .font(.headline)
                .foregroundStyle(Color.vitalyTextSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Text(insight.content)
                .font(.body)
                .foregroundStyle(Color.vitalyTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
    }

    // MARK: - Metrics Section

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Relaterade mätvärden")
                .font(.headline)
                .foregroundStyle(Color.vitalyTextSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            FlowLayout(spacing: 10) {
                ForEach(insight.metrics, id: \.self) { metric in
                    metricTag(metric)
                }
            }
        }
    }

    private func metricTag(_ metric: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: metricIcon(for: metric))
                .font(.caption)

            Text(metricName(for: metric))
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.vitalySurface)
                .overlay(
                    Capsule()
                        .stroke(metricColor(for: metric).opacity(0.3), lineWidth: 1)
                )
        )
        .foregroundStyle(metricColor(for: metric))
    }

    // MARK: - Priority Badge

    private var priorityBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)

            Text(priorityText)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.white.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
        )
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
            return LinearGradient.vitalyGradient
        case .low:
            return LinearGradient(
                colors: [Color.vitalyTextSecondary, Color.vitalyTextSecondary.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var priorityColor: Color {
        switch insight.priority {
        case .high: return .vitalyHeart
        case .normal: return .vitalyPrimary
        case .low: return .vitalyTextSecondary
        }
    }

    private var priorityText: String {
        switch insight.priority {
        case .high: return "Hög prioritet"
        case .normal: return "Normal"
        case .low: return "Låg prioritet"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter.string(from: insight.createdAt)
    }

    private var shareText: String {
        """
        \(insight.title)

        \(insight.content)

        Skapad: \(formattedDate)
        """
    }

    // MARK: - Helper Functions

    private func metricIcon(for metric: String) -> String {
        switch metric {
        case "sleep": return "moon.fill"
        case "activity": return "figure.run"
        case "heart": return "heart.fill"
        case "recovery": return "battery.100.bolt"
        default: return "chart.bar.fill"
        }
    }

    private func metricName(for metric: String) -> String {
        switch metric {
        case "sleep": return "Sömn"
        case "activity": return "Aktivitet"
        case "heart": return "Hjärta"
        case "recovery": return "Återhämtning"
        default: return metric.capitalized
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

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview("Normal Priority") {
    InsightDetailView(
        insight: AIInsight(
            id: "1",
            type: .dailySummary,
            title: "Daglig sammanfattning",
            content: """
            Du har haft en bra dag idag! Din sömn var utmärkt med 8 timmar och 15 minuter, \
            varav 1 timme och 45 minuter djupsömn och 2 timmar REM-sömn. Din sömnkvalitet \
            bedöms som utmärkt.

            Din aktivitetsnivå har också varit bra med 10,234 steg och 45 minuters träning. \
            Du har bränt 487 aktiva kalorier.

            Din vilopuls är stabil på 62 bpm, vilket är ett tecken på god kardiovaskulär hälsa. \
            Din HRV är 48 ms, vilket är bra och indikerar god återhämtning.

            Tips: Försök att upprätthålla denna goda balans mellan sömn, aktivitet och återhämtning. \
            Du är på rätt väg mot dina hälsomål!
            """,
            metrics: ["sleep", "activity", "heart"],
            createdAt: Date(),
            isRead: false,
            priority: .normal
        ),
        onAppear: {}
    )
}

#Preview("High Priority") {
    InsightDetailView(
        insight: AIInsight(
            id: "2",
            type: .sleepAnalysis,
            title: "Sömnanalys",
            content: """
            Din sömnkvalitet har varit låg de senaste tre dagarna. Analys visar följande:

            - Genomsnittlig sömntid: 5 timmar 45 minuter (under rekommenderat)
            - Djupsömn: Endast 35 minuter per natt (bör vara 1-2 timmar)
            - REM-sömn: 45 minuter per natt (bör vara 1.5-2 timmar)
            - Antal uppvaknanden: 4-6 gånger per natt

            Rekommendationer:
            1. Gå och lägg dig senast kl. 23:00 för att få 7-8 timmars sömn
            2. Undvik skärmar minst 1 timme innan läggdags
            3. Håll sovrummet svalt (16-19°C) och mörkt
            4. Undvik koffein efter lunch
            5. Överväg avslappningsövningar innan läggdags
            """,
            metrics: ["sleep"],
            createdAt: Date().addingTimeInterval(-3600),
            isRead: false,
            priority: .high
        ),
        onAppear: {}
    )
}
