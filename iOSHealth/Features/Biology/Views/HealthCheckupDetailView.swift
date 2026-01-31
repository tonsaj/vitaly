import SwiftUI

struct HealthCheckupDetailView: View {
    let checkup: HealthCheckup

    @State private var expandedValueId: String?
    @State private var labInsights: [String: String] = [:]
    @State private var loadingValueId: String?
    @State private var failedValueIds: Set<String> = []

    var body: some View {
        ZStack {
            Color.vitalyBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard

                    if let summary = checkup.aiSummary, !summary.isEmpty {
                        aiSummaryCard(summary)
                    }

                    outOfRangeBanner

                    ForEach(checkup.categories, id: \.self) { category in
                        categorySection(category)
                    }
                }
                .padding(.bottom, 40)
            }
            .scrollBounceBehavior(.basedOnSize)
            .clipped()
            .contentShape(Rectangle())
        }
        .navigationTitle("Checkup Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.vitalyCardBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(checkup.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(checkup.formattedDate)
                            .font(.subheadline)
                    }
                    .foregroundStyle(Color.vitalyTextSecondary)

                    if let provider = checkup.provider, !provider.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "building.2.fill")
                                .font(.caption)
                            Text(provider)
                                .font(.subheadline)
                        }
                        .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.vitalyPrimary.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.vitalyPrimary)
                }
            }

            HStack(spacing: 16) {
                statPill(
                    icon: "list.bullet",
                    value: "\(checkup.labValues.count)",
                    label: "Lab values"
                )
                statPill(
                    icon: "folder.fill",
                    value: "\(checkup.categories.count)",
                    label: "Categories"
                )
                if checkup.outOfRangeCount > 0 {
                    statPill(
                        icon: "exclamationmark.triangle.fill",
                        value: "\(checkup.outOfRangeCount)",
                        label: "Out of range",
                        tint: .vitalyHeart
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func statPill(icon: String, value: String, label: String, tint: Color = .vitalyPrimary) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(tint)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.vitalyTextPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.vitalySurface)
        )
    }

    // MARK: - AI Summary Card

    private func aiSummaryCard(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vitalyPrimary)

                Text("AI Summary")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            Text(summary)
                .font(.body)
                .foregroundStyle(Color.vitalyTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.vitalyPrimary.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }

    // MARK: - Out of Range Banner

    @ViewBuilder
    private var outOfRangeBanner: some View {
        if checkup.outOfRangeCount > 0 {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.vitalyHeart)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(checkup.outOfRangeCount) value\(checkup.outOfRangeCount == 1 ? "" : "s") out of range")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Text("Values outside the normal reference range are highlighted below")
                        .font(.caption)
                        .foregroundStyle(Color.vitalyTextSecondary)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.vitalyHeart.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.vitalyHeart.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
        }
    }

    // MARK: - Category Section

    private func categorySection(_ category: LabCategory) -> some View {
        let values = checkup.labValues.filter { $0.category == category }

        return VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(category.color.opacity(0.15))
                        .frame(width: 32, height: 32)

                    Image(systemName: category.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(category.color)
                }

                Text(category.displayName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Spacer()

                let outOfRange = values.filter(\.isOutOfRange).count
                if outOfRange > 0 {
                    Text("\(outOfRange) flagged")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.vitalyHeart)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.vitalyHeart.opacity(0.12))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            // Lab value rows
            VStack(spacing: 1) {
                ForEach(values) { labValue in
                    labValueRow(labValue, categoryColor: category.color)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }

    // MARK: - Lab Value Row

    private func labValueRow(_ labValue: LabValue, categoryColor: Color) -> some View {
        let isExpanded = expandedValueId == labValue.id
        let isLoading = loadingValueId == labValue.id

        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(labValue.isOutOfRange ? Color.vitalyHeart.opacity(0.15) : Color.vitalyExcellent.opacity(0.15))
                        .frame(width: 28, height: 28)

                    if labValue.isOutOfRange {
                        Image(systemName: "exclamationmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.vitalyHeart)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.vitalyExcellent)
                    }
                }

                // Name and reference range
                VStack(alignment: .leading, spacing: 3) {
                    Text(labValue.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    if let rangeText = labValue.referenceRangeText {
                        Text("Ref: \(rangeText)")
                            .font(.caption2)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }

                Spacer()

                // Value and status
                VStack(alignment: .trailing, spacing: 3) {
                    Text(labValue.formattedValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(labValue.isOutOfRange ? Color.vitalyHeart : Color.vitalyTextPrimary)

                    Text(labValue.statusText)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(labValue.isOutOfRange ? Color.vitalyHeart : Color.vitalyExcellent)
                }

                // Info icon
                Image(systemName: isExpanded ? "info.circle.fill" : "info.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isExpanded ? Color.vitalyPrimary : Color.vitalyTextSecondary.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if isExpanded {
                        expandedValueId = nil
                    } else {
                        expandedValueId = labValue.id
                        if labInsights[labValue.id] == nil || failedValueIds.contains(labValue.id) {
                            failedValueIds.remove(labValue.id)
                            labInsights.removeValue(forKey: labValue.id)
                            loadInsight(for: labValue)
                        }
                    }
                }
            }

            // Expanded AI insight
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.vitalyPrimary)

                        Text("AI Analysis")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.vitalyTextSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }

                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(Color.vitalyPrimary)
                                .scaleEffect(0.8)
                            Text("Analyzing...")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }
                    } else if let insight = labInsights[labValue.id] {
                        Text(insight)
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(3)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            labValue.isOutOfRange
                ? Color.vitalyHeart.opacity(0.05)
                : Color.vitalySurface.opacity(0.3)
        )
    }

    private func loadInsight(for labValue: LabValue) {
        loadingValueId = labValue.id
        Task {
            do {
                let insight = try await GeminiService.shared.generateLabValueInsight(labValue: labValue)
                await MainActor.run {
                    labInsights[labValue.id] = insight
                    loadingValueId = nil
                }
            } catch {
                await MainActor.run {
                    labInsights[labValue.id] = "Could not load analysis. Tap to try again."
                    failedValueIds.insert(labValue.id)
                    loadingValueId = nil
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Full Checkup") {
    NavigationStack {
        HealthCheckupDetailView(
            checkup: HealthCheckup(
                date: Date(),
                title: "Annual Blood Work",
                provider: "Stockholm Health Center",
                labValues: [
                    LabValue(
                        name: "Total Cholesterol",
                        value: 5.2,
                        unit: "mmol/L",
                        referenceMin: 3.0,
                        referenceMax: 5.0,
                        category: .cholesterol
                    ),
                    LabValue(
                        name: "LDL Cholesterol",
                        value: 2.8,
                        unit: "mmol/L",
                        referenceMin: 1.0,
                        referenceMax: 3.0,
                        category: .cholesterol
                    ),
                    LabValue(
                        name: "HDL Cholesterol",
                        value: 1.6,
                        unit: "mmol/L",
                        referenceMin: 1.0,
                        referenceMax: 2.5,
                        category: .cholesterol
                    ),
                    LabValue(
                        name: "Fasting Glucose",
                        value: 5.1,
                        unit: "mmol/L",
                        referenceMin: 3.9,
                        referenceMax: 5.6,
                        category: .bloodSugar
                    ),
                    LabValue(
                        name: "HbA1c",
                        value: 38,
                        unit: "mmol/mol",
                        referenceMin: 20,
                        referenceMax: 42,
                        category: .bloodSugar
                    ),
                    LabValue(
                        name: "ALT",
                        value: 45,
                        unit: "U/L",
                        referenceMin: 10,
                        referenceMax: 40,
                        category: .liver
                    ),
                    LabValue(
                        name: "TSH",
                        value: 2.1,
                        unit: "mIU/L",
                        referenceMin: 0.4,
                        referenceMax: 4.0,
                        category: .thyroid
                    ),
                    LabValue(
                        name: "Vitamin D",
                        value: 42,
                        unit: "nmol/L",
                        referenceMin: 50,
                        referenceMax: 125,
                        category: .vitamins
                    ),
                    LabValue(
                        name: "CRP",
                        value: 1.2,
                        unit: "mg/L",
                        referenceMin: 0,
                        referenceMax: 5.0,
                        category: .inflammation
                    )
                ],
                aiSummary: "Overall results are good with a few areas to monitor. Total cholesterol is slightly elevated at 5.2 mmol/L. ALT liver enzyme is mildly above reference range. Vitamin D is below optimal levels at 42 nmol/L and supplementation is recommended. All other values are within normal ranges."
            )
        )
    }
}

#Preview("Minimal Checkup") {
    NavigationStack {
        HealthCheckupDetailView(
            checkup: HealthCheckup(
                date: Date().addingTimeInterval(-86400 * 30),
                title: "Routine Blood Test",
                labValues: [
                    LabValue(
                        name: "Hemoglobin",
                        value: 145,
                        unit: "g/L",
                        referenceMin: 130,
                        referenceMax: 170,
                        category: .bloodCount
                    ),
                    LabValue(
                        name: "Creatinine",
                        value: 82,
                        unit: "umol/L",
                        referenceMin: 60,
                        referenceMax: 105,
                        category: .kidney
                    )
                ]
            )
        )
    }
}
