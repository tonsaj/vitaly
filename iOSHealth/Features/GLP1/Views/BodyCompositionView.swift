import SwiftUI

struct BodyCompositionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var glp1Service: GLP1Service

    @State private var date = Date()
    @State private var weight: String = ""
    @State private var bodyFat: String = ""
    @State private var muscleMass: String = ""
    @State private var waterPercentage: String = ""
    @State private var visceralFat: String = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Info banner
                        infoBanner

                        // Date
                        dateSection

                        // Weight (required)
                        weightSection

                        // Body composition (optional)
                        bodyCompositionSection

                        // History
                        if !glp1Service.bodyCompositions.isEmpty {
                            historySection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }

                // Save Button
                VStack {
                    Spacer()

                    Button {
                        saveAndDismiss()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isValid ? LinearGradient.vitalyGradient : LinearGradient(colors: [Color.vitalySurface], startPoint: .leading, endPoint: .trailing))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .disabled(!isValid || isSaving)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Body Composition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
        }
    }

    private var isValid: Bool {
        guard let w = Double(weight), w > 0 else { return false }
        return true
    }

    // MARK: - Info Banner

    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .foregroundStyle(Color.vitalySleep)

            Text("Use data from a smart scale for accurate body composition tracking")
                .font(.caption)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
        .padding()
        .background(Color.vitalySleep.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VitalyCard {
            HStack {
                Text("Date")
                    .font(.subheadline)
                    .foregroundStyle(Color.vitalyTextPrimary)

                Spacer()

                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .tint(Color.vitalyPrimary)
            }
            .padding(20)
        }
    }

    // MARK: - Weight Section

    private var weightSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "scalemass")
                        .foregroundStyle(Color.vitalyPrimary)
                    Text("WEIGHT *")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                HStack {
                    TextField("0.0", text: $weight)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Text("kg")
                        .font(.title3)
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
                .padding()
                .background(Color.vitalySurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(20)
        }
    }

    // MARK: - Body Composition Section

    private var bodyCompositionSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "figure.arms.open")
                        .foregroundStyle(Color.vitalyActivity)
                    Text("BODY COMPOSITION (OPTIONAL)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                // Body Fat
                compositionField(
                    label: "Body Fat",
                    value: $bodyFat,
                    unit: "%",
                    icon: "percent"
                )

                Divider().background(Color.vitalySurface)

                // Muscle Mass
                compositionField(
                    label: "Muscle Mass",
                    value: $muscleMass,
                    unit: "kg",
                    icon: "figure.strengthtraining.traditional"
                )

                Divider().background(Color.vitalySurface)

                // Water Percentage
                compositionField(
                    label: "Water",
                    value: $waterPercentage,
                    unit: "%",
                    icon: "drop.fill"
                )

                Divider().background(Color.vitalySurface)

                // Visceral Fat
                compositionField(
                    label: "Visceral Fat",
                    value: $visceralFat,
                    unit: "level",
                    icon: "heart.fill"
                )
            }
            .padding(20)
        }
    }

    private func compositionField(label: String, value: Binding<String>, unit: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.vitalyTextSecondary)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.vitalyTextPrimary)

            Spacer()

            HStack(spacing: 4) {
                TextField("--", text: value)
                    .keyboardType(.decimalPad)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)

                Text(unit)
                    .font(.caption)
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .frame(width: 40, alignment: .leading)
            }
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(Color.vitalyPrimary)
                    Text("RECENT ENTRIES")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                VStack(spacing: 12) {
                    ForEach(glp1Service.bodyCompositions.prefix(5)) { comp in
                        HStack {
                            Text(comp.date, format: .dateTime.month().day())
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                                .frame(width: 50, alignment: .leading)

                            Text(String(format: "%.1f kg", comp.weight))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.vitalyTextPrimary)

                            Spacer()

                            if let fat = comp.bodyFatPercentage {
                                HStack(spacing: 4) {
                                    Text(String(format: "%.1f%%", fat))
                                        .font(.caption)
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                    Text("fat")
                                        .font(.caption2)
                                        .foregroundStyle(Color.vitalyTextSecondary.opacity(0.7))
                                }
                            }

                            if let muscle = comp.muscleMass {
                                HStack(spacing: 4) {
                                    Text(String(format: "%.1f", muscle))
                                        .font(.caption)
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                    Text("muscle")
                                        .font(.caption2)
                                        .foregroundStyle(Color.vitalyTextSecondary.opacity(0.7))
                                }
                            }
                        }
                    }
                }

                // Muscle mass change warning
                if let change = glp1Service.muscleMassChange, change < -0.5 {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.yellow)

                        Text("Muscle mass decreased by \(String(format: "%.1f", abs(change))) kg - consider increasing protein intake")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(20)
        }
    }

    // MARK: - Save

    private func saveAndDismiss() {
        guard let w = Double(weight) else { return }

        isSaving = true

        let comp = BodyComposition(
            date: date,
            weight: w,
            bodyFatPercentage: Double(bodyFat),
            muscleMass: Double(muscleMass),
            waterPercentage: Double(waterPercentage),
            visceralFat: Int(visceralFat)
        )

        Task {
            do {
                try await glp1Service.logBodyComposition(comp)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error logging body composition: \(error)")
                isSaving = false
            }
        }
    }
}

#Preview {
    BodyCompositionView(glp1Service: GLP1Service())
}
