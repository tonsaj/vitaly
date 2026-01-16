import SwiftUI

struct SideEffectsLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var glp1Service: GLP1Service

    @State private var date = Date()
    @State private var nausea: Double = 1
    @State private var appetite: Double = 5
    @State private var energy: Double = 5
    @State private var constipation: Double = 1
    @State private var headache: Double = 1
    @State private var fatigue: Double = 1
    @State private var notes: String = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Date
                        dateSection

                        // Main symptoms
                        mainSymptomsSection

                        // Other symptoms
                        otherSymptomsSection

                        // Notes
                        notesSection
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
                    .background(LinearGradient.vitalyGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .disabled(isSaving)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Log Side Effects")
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

    // MARK: - Main Symptoms

    private var mainSymptomsSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "heart.text.square")
                        .foregroundStyle(Color.vitalyPrimary)
                    Text("MAIN SYMPTOMS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                // Nausea
                symptomSlider(
                    icon: "face.smiling",
                    label: "Nausea",
                    value: $nausea,
                    lowLabel: "None",
                    highLabel: "Severe",
                    color: nauseaColor(nausea)
                )

                Divider().background(Color.vitalySurface)

                // Appetite
                symptomSlider(
                    icon: "fork.knife",
                    label: "Appetite",
                    value: $appetite,
                    lowLabel: "None",
                    highLabel: "Very hungry",
                    color: Color.vitalyActivity
                )

                Divider().background(Color.vitalySurface)

                // Energy
                symptomSlider(
                    icon: "bolt.fill",
                    label: "Energy Level",
                    value: $energy,
                    lowLabel: "Exhausted",
                    highLabel: "Energetic",
                    color: energyColor(energy)
                )
            }
            .padding(20)
        }
    }

    // MARK: - Other Symptoms

    private var otherSymptomsSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "list.bullet.clipboard")
                        .foregroundStyle(Color.vitalySleep)
                    Text("OTHER SYMPTOMS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                // Constipation
                symptomSlider(
                    icon: "stomach",
                    label: "Constipation",
                    value: $constipation,
                    lowLabel: "None",
                    highLabel: "Severe",
                    color: Color.vitalyTextSecondary
                )

                Divider().background(Color.vitalySurface)

                // Headache
                symptomSlider(
                    icon: "brain.head.profile",
                    label: "Headache",
                    value: $headache,
                    lowLabel: "None",
                    highLabel: "Severe",
                    color: Color.vitalyTextSecondary
                )

                Divider().background(Color.vitalySurface)

                // Fatigue
                symptomSlider(
                    icon: "moon.zzz",
                    label: "Fatigue",
                    value: $fatigue,
                    lowLabel: "None",
                    highLabel: "Severe",
                    color: Color.vitalyTextSecondary
                )
            }
            .padding(20)
        }
    }

    private func symptomSlider(icon: String, label: String, value: Binding<Double>, lowLabel: String, highLabel: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 24)

                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Spacer()

                Text("\(Int(value.wrappedValue))")
                    .font(.headline)
                    .foregroundStyle(color)
                    .frame(width: 30)
            }

            Slider(value: value, in: 1...10, step: 1)
                .tint(color)

            HStack {
                Text(lowLabel)
                    .font(.caption2)
                    .foregroundStyle(Color.vitalyTextSecondary)

                Spacer()

                Text(highLabel)
                    .font(.caption2)
                    .foregroundStyle(Color.vitalyTextSecondary)
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundStyle(Color.vitalyPrimary)
                    Text("NOTES (OPTIONAL)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                TextField("How are you feeling today?", text: $notes, axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(Color.vitalyTextPrimary)
                    .padding()
                    .background(Color.vitalySurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .lineLimit(3...6)
            }
            .padding(20)
        }
    }

    // MARK: - Colors

    private func nauseaColor(_ value: Double) -> Color {
        if value <= 3 { return .green }
        if value <= 6 { return .yellow }
        return .orange
    }

    private func energyColor(_ value: Double) -> Color {
        if value >= 7 { return .green }
        if value >= 4 { return .yellow }
        return .orange
    }

    // MARK: - Save

    private func saveAndDismiss() {
        isSaving = true

        let log = SideEffectLog(
            date: date,
            nausea: Int(nausea),
            appetite: Int(appetite),
            energy: Int(energy),
            constipation: Int(constipation) > 1 ? Int(constipation) : nil,
            headache: Int(headache) > 1 ? Int(headache) : nil,
            fatigue: Int(fatigue) > 1 ? Int(fatigue) : nil,
            notes: notes.isEmpty ? nil : notes
        )

        Task {
            do {
                try await glp1Service.logSideEffects(log)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error logging side effects: \(error)")
                isSaving = false
            }
        }
    }
}

#Preview {
    SideEffectsLogView(glp1Service: GLP1Service())
}
