import SwiftUI
import Charts

struct RecoveryView: View {
    let viewModel: HealthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Main Recovery Score
                recoveryScoreCard

                // Readiness Indicator
                readinessCard

                // Contributing Factors
                contributingFactorsCard

                // Recommendations
                recommendationsCard

                // Recovery Trend
                recoveryTrendCard
            }
            .padding()
        }
        .background(Color.vitalyBackground)
        .navigationTitle("Återhämtning")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Recovery Score Card
    private var recoveryScoreCard: some View {
        VStack(spacing: 20) {
            // Animated recovery ring
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.vitalySurface, lineWidth: 24)
                    .frame(width: 200, height: 200)

                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.recoveryScore) / 100)
                    .stroke(
                        .angularGradient(
                            colors: recoveryGradientColors,
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: statusColor.opacity(0.5), radius: 12, x: 0, y: 6)

                // Inner content
                VStack(spacing: 8) {
                    Text("\(viewModel.recoveryScore)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.vitalyTextPrimary)

                    Text("Återhämtning")
                        .font(.caption)
                        .foregroundColor(.vitalyTextSecondary)
                }
            }

            // Status badge
            HStack(spacing: 8) {
                Image(systemName: viewModel.recoveryStatus.icon)
                    .font(.title3)
                Text(viewModel.recoveryStatus.displayText)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .foregroundColor(statusColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.15))
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.vitalyCardBackground)
        )
    }

    private var statusColor: Color {
        switch viewModel.recoveryStatus {
        case .optimal: return .vitalyRecovery
        case .good: return .vitalyGood
        case .fair: return .vitalyFair
        case .needsRest: return .vitalyPoor
        }
    }

    private var recoveryGradientColors: [Color] {
        switch viewModel.recoveryScore {
        case 80...: return [Color.vitalyRecovery, Color(red: 1.0, green: 0.8, blue: 0.4)]
        case 65..<80: return [Color.vitalyGood, Color.vitalyRecovery]
        case 50..<65: return [Color.vitalyFair, Color.vitalyActivity]
        default: return [Color.vitalyPoor, Color.vitalyHeart]
        }
    }

    // MARK: - Readiness Card
    private var readinessCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.run")
                    .font(.title2)
                    .foregroundColor(readinessColor)

                Text("Träningsberedskap")
                    .font(.headline)
                    .foregroundColor(.vitalyTextPrimary)

                Spacer()
            }

            HStack(spacing: 16) {
                // Readiness indicator
                ZStack {
                    Circle()
                        .fill(readinessColor.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: readinessIcon)
                        .font(.system(size: 36))
                        .foregroundColor(readinessColor)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(readinessTitle)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.vitalyTextPrimary)

                    Text(readinessDescription)
                        .font(.subheadline)
                        .foregroundColor(.vitalyTextSecondary)
                        .lineLimit(3)
                }

                Spacer()
            }

            // Training recommendation bar
            VStack(alignment: .leading, spacing: 8) {
                Text("Rekommenderad intensitet")
                    .font(.caption)
                    .foregroundColor(.vitalyTextSecondary)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background bar with zones
                        HStack(spacing: 2) {
                            Rectangle()
                                .fill(Color.vitalyExcellent.opacity(0.3))
                            Rectangle()
                                .fill(Color.vitalyFair.opacity(0.3))
                            Rectangle()
                                .fill(Color.vitalyPoor.opacity(0.3))
                        }
                        .frame(height: 12)
                        .cornerRadius(6)

                        // Indicator
                        Circle()
                            .fill(readinessColor)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.vitalyTextPrimary, lineWidth: 3)
                            )
                            .shadow(color: readinessColor.opacity(0.4), radius: 4, x: 0, y: 2)
                            .offset(x: (geometry.size.width - 20) * CGFloat(viewModel.recoveryScore) / 100.0)
                    }
                }
                .frame(height: 20)

                HStack {
                    Text("Vila")
                        .font(.caption2)
                        .foregroundColor(.vitalyTextSecondary)
                    Spacer()
                    Text("Måttlig")
                        .font(.caption2)
                        .foregroundColor(.vitalyTextSecondary)
                    Spacer()
                    Text("Hög")
                        .font(.caption2)
                        .foregroundColor(.vitalyTextSecondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
        )
    }

    private var readinessColor: Color {
        statusColor
    }

    private var readinessIcon: String {
        switch viewModel.recoveryStatus {
        case .optimal: return "bolt.fill"
        case .good: return "checkmark.circle.fill"
        case .fair: return "exclamationmark.circle.fill"
        case .needsRest: return "bed.double.fill"
        }
    }

    private var readinessTitle: String {
        switch viewModel.recoveryStatus {
        case .optimal: return "Redo att prestera"
        case .good: return "Kan träna normalt"
        case .fair: return "Lättare träning"
        case .needsRest: return "Behöver vila"
        }
    }

    private var readinessDescription: String {
        switch viewModel.recoveryStatus {
        case .optimal:
            return "Din kropp är optimalt återhämtad. Perfekt för intensiva pass och tävling."
        case .good:
            return "Bra återhämtning. Du kan träna som vanligt men håll koll på din kropp."
        case .fair:
            return "Måttlig återhämtning. Rekommenderar lättare träning eller aktiv vila."
        case .needsRest:
            return "Din kropp behöver mer vila. Prioritera sömn och återhämtning."
        }
    }

    // MARK: - Contributing Factors Card
    private var contributingFactorsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.title3)
                    .foregroundColor(.vitalyRecovery)

                Text("Bidragande faktorer")
                    .font(.headline)
                    .foregroundColor(.vitalyTextPrimary)

                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(viewModel.recoveryFactors, id: \.0) { factor in
                    factorRow(
                        name: factor.0,
                        value: factor.1,
                        status: factor.2
                    )
                }
            }

            // Info box
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color(red: 0.4, green: 0.75, blue: 0.85))
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Återhämtningspoäng")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.vitalyTextPrimary)

                    Text("Beräknas från sömnkvalitet (60%) och HRV (40%)")
                        .font(.caption2)
                        .foregroundColor(.vitalyTextSecondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.4, green: 0.75, blue: 0.85).opacity(0.15))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
        )
    }

    private func factorRow(name: String, value: String, status: RecoveryFactorStatus) -> some View {
        HStack {
            HStack(spacing: 12) {
                Circle()
                    .fill(factorStatusColor(status))
                    .frame(width: 10, height: 10)

                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.vitalyTextPrimary)
            }

            Spacer()

            HStack(spacing: 8) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.vitalyTextPrimary)

                Image(systemName: statusIcon(status))
                    .font(.caption)
                    .foregroundColor(factorStatusColor(status))
            }
        }
        .padding(.vertical, 8)
    }

    private func factorStatusColor(_ status: RecoveryFactorStatus) -> Color {
        switch status {
        case .positive: return .vitalyExcellent
        case .neutral: return .vitalyFair
        case .negative: return .vitalyPoor
        }
    }

    private func statusIcon(_ status: RecoveryFactorStatus) -> String {
        switch status {
        case .positive: return "arrow.up.circle.fill"
        case .neutral: return "minus.circle.fill"
        case .negative: return "arrow.down.circle.fill"
        }
    }

    // MARK: - Recommendations Card
    private var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundColor(.vitalyRecovery)

                Text("Rekommendationer")
                    .font(.headline)
                    .foregroundColor(.vitalyTextPrimary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 16) {
                // Main recommendation
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "quote.opening")
                        .font(.title2)
                        .foregroundColor(statusColor.opacity(0.5))
                        .padding(.top, 4)

                    Text(viewModel.recoveryRecommendation)
                        .font(.body)
                        .foregroundColor(.vitalyTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(statusColor.opacity(0.15))
                )

                // Action items
                VStack(alignment: .leading, spacing: 10) {
                    recommendationItem(
                        icon: "moon.stars.fill",
                        text: "Sikta på 7-9 timmars sömn",
                        color: .vitalySleep
                    )

                    recommendationItem(
                        icon: "drop.fill",
                        text: "Drick tillräckligt med vatten",
                        color: Color(red: 0.4, green: 0.75, blue: 0.85)
                    )

                    if viewModel.recoveryScore < 70 {
                        recommendationItem(
                            icon: "figure.yoga",
                            text: "Överväg stretching eller yoga",
                            color: Color(red: 0.7, green: 0.5, blue: 0.85)
                        )
                    }

                    if viewModel.recoveryScore >= 80 {
                        recommendationItem(
                            icon: "figure.strengthtraining.traditional",
                            text: "Bra dag för styrketräning",
                            color: .vitalyActivity
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
        )
    }

    private func recommendationItem(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.vitalyTextSecondary)

            Spacer()
        }
    }

    // MARK: - Recovery Trend Card
    private var recoveryTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Återhämtningstrend")
                    .font(.headline)
                    .foregroundColor(.vitalyTextPrimary)

                Spacer()

                Text("7 dagar")
                    .font(.caption)
                    .foregroundColor(.vitalyTextSecondary)
            }

            Chart {
                ForEach(historicalRecoveryData) { item in
                    LineMark(
                        x: .value("Dag", item.date, unit: .day),
                        y: .value("Poäng", item.score)
                    )
                    .foregroundStyle(LinearGradient.vitalyRecoveryGradient)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Dag", item.date, unit: .day),
                        y: .value("Poäng", item.score)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                Color.vitalyRecovery.opacity(0.3),
                                Color.vitalyRecovery.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Dag", item.date, unit: .day),
                        y: .value("Poäng", item.score)
                    )
                    .foregroundStyle(Color.vitalyRecovery)
                    .symbol(.circle)
                }

                // Threshold lines
                RuleMark(y: .value("Optimal", 80))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(Color.vitalyExcellent.opacity(0.3))

                RuleMark(y: .value("Bra", 65))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(Color.vitalyFair.opacity(0.3))
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
                        if let score = value.as(Int.self) {
                            Text("\(score)")
                                .font(.caption2)
                                .foregroundColor(.vitalyTextSecondary)
                        }
                    }
                }
            }
            .frame(height: 180)

            // Statistics
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Genomsnitt")
                        .font(.caption)
                        .foregroundColor(.vitalyTextSecondary)
                    Text("\(averageRecoveryScore)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.vitalyTextPrimary)
                }

                Divider()
                    .frame(height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Högsta")
                        .font(.caption)
                        .foregroundColor(.vitalyTextSecondary)
                    Text("\(maxRecoveryScore)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.vitalyExcellent)
                }

                Divider()
                    .frame(height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Lägsta")
                        .font(.caption)
                        .foregroundColor(.vitalyTextSecondary)
                    Text("\(minRecoveryScore)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.vitalyFair)
                }

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
        )
    }

    // MARK: - Historical Recovery Data
    private var historicalRecoveryData: [RecoveryDataPoint] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: viewModel.selectedDate) ?? Date()
            // Calculate mock recovery score from historical data
            let score = Int.random(in: 50...95)
            return RecoveryDataPoint(id: UUID().uuidString, date: date, score: score)
        }
    }

    private var averageRecoveryScore: Int {
        let total = historicalRecoveryData.reduce(0) { $0 + $1.score }
        return total / historicalRecoveryData.count
    }

    private var maxRecoveryScore: Int {
        historicalRecoveryData.map { $0.score }.max() ?? 0
    }

    private var minRecoveryScore: Int {
        historicalRecoveryData.map { $0.score }.min() ?? 0
    }

    // MARK: - Helper Functions
    private func formatShortWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "sv_SE")
        return formatter.string(from: date).capitalized
    }
}

// MARK: - Supporting Types
struct RecoveryDataPoint: Identifiable {
    let id: String
    let date: Date
    let score: Int
}

// MARK: - Preview
#Preview {
    NavigationStack {
        RecoveryView(
            viewModel: {
                let vm = HealthViewModel()
                Task {
                    await vm.fetchData()
                }
                return vm
            }()
        )
    }
}
