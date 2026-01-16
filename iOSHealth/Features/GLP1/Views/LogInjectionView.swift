import SwiftUI

struct LogInjectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var glp1Service: GLP1Service

    @State private var date = Date()
    @State private var dose: Double = 0
    @State private var injectionSite: MedicationLog.InjectionSite = .abdomen
    @State private var notes: String = ""
    @State private var skipped = false
    @State private var skipReason: String = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Skip toggle
                        skipSection

                        if !skipped {
                            // Injection details
                            injectionDetailsSection

                            // Injection site
                            injectionSiteSection
                        } else {
                            // Skip reason
                            skipReasonSection
                        }

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
                            Text(skipped ? "Log Skipped Dose" : "Log Injection")
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
            .navigationTitle("Log Injection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
            .onAppear {
                if let treatment = glp1Service.treatment {
                    dose = treatment.currentDose
                }
            }
        }
    }

    // MARK: - Skip Section

    private var skipSection: some View {
        VitalyCard {
            Toggle(isOn: $skipped) {
                HStack(spacing: 12) {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(skipped ? Color.vitalyPrimary : Color.vitalyTextSecondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Skip this dose")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Text("Log if you missed or skipped your injection")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }
            }
            .tint(Color.vitalyPrimary)
            .padding(20)
        }
    }

    // MARK: - Injection Details

    private var injectionDetailsSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "syringe")
                        .foregroundStyle(Color.vitalyPrimary)
                    Text("INJECTION DETAILS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                // Date
                HStack {
                    Text("Date & Time")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Spacer()

                    DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .tint(Color.vitalyPrimary)
                }

                Divider()
                    .background(Color.vitalySurface)

                // Dose
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dose")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextPrimary)

                    if let treatment = glp1Service.treatment {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(treatment.medication.doseSchedule, id: \.self) { d in
                                    Button {
                                        dose = d
                                    } label: {
                                        Text("\(d, specifier: "%.2g") mg")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(dose == d ? .white : Color.vitalyTextPrimary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(dose == d ? Color.vitalyPrimary : Color.vitalySurface)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Injection Site

    private var injectionSiteSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "figure.stand")
                        .foregroundStyle(Color.vitalyPrimary)
                    Text("INJECTION SITE")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                HStack(spacing: 12) {
                    ForEach(MedicationLog.InjectionSite.allCases, id: \.self) { site in
                        Button {
                            injectionSite = site
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: site.icon)
                                    .font(.system(size: 24))
                                    .foregroundStyle(injectionSite == site ? Color.vitalyPrimary : Color.vitalyTextSecondary)

                                Text(site.displayName)
                                    .font(.caption)
                                    .foregroundStyle(injectionSite == site ? Color.vitalyTextPrimary : Color.vitalyTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(injectionSite == site ? Color.vitalyPrimary.opacity(0.1) : Color.vitalySurface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(injectionSite == site ? Color.vitalyPrimary : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Skip Reason

    private var skipReasonSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "text.bubble")
                        .foregroundStyle(Color.vitalyPrimary)
                    Text("REASON FOR SKIPPING")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                let reasons = ["Forgot", "Side effects", "Traveling", "Doctor's advice", "Other"]

                VStack(spacing: 8) {
                    ForEach(reasons, id: \.self) { reason in
                        Button {
                            skipReason = reason
                        } label: {
                            HStack {
                                Text(reason)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.vitalyTextPrimary)

                                Spacer()

                                Image(systemName: skipReason == reason ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(skipReason == reason ? Color.vitalyPrimary : Color.vitalyTextSecondary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(skipReason == reason ? Color.vitalyPrimary.opacity(0.1) : Color.vitalySurface)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
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

                TextField("Add any notes...", text: $notes, axis: .vertical)
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

    // MARK: - Save

    private func saveAndDismiss() {
        guard let treatment = glp1Service.treatment else { return }

        isSaving = true

        let log = MedicationLog(
            date: date,
            dose: dose,
            medication: treatment.medication,
            injectionSite: skipped ? nil : injectionSite,
            notes: notes.isEmpty ? nil : notes,
            skipped: skipped,
            skipReason: skipped ? skipReason : nil
        )

        Task {
            do {
                try await glp1Service.logMedication(log)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error logging medication: \(error)")
                isSaving = false
            }
        }
    }
}

#Preview {
    LogInjectionView(glp1Service: GLP1Service())
}
