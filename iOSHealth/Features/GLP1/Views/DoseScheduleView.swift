import SwiftUI

struct DoseScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var glp1Service: GLP1Service

    @State private var showingDoseUpdate = false
    @State private var selectedNewDose: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                if let treatment = glp1Service.treatment {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Current Status
                            currentStatusCard(treatment)

                            // Dose Schedule
                            doseScheduleCard(treatment)

                            // Guidelines
                            guidelinesCard

                            // Increase Dose Button
                            if treatment.isReadyForDoseIncrease, let nextDose = treatment.nextDose {
                                increaseDoseButton(nextDose: nextDose)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                } else {
                    Text("No active treatment")
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
            .navigationTitle("Dose Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.vitalyPrimary)
                }
            }
            .alert("Increase Dose", isPresented: $showingDoseUpdate) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm") {
                    updateDose()
                }
            } message: {
                Text("Are you sure you want to increase your dose to \(selectedNewDose, specifier: "%.2g") mg? Make sure this is in line with your doctor's recommendations.")
            }
        }
    }

    // MARK: - Current Status

    private func currentStatusCard(_ treatment: GLP1Treatment) -> some View {
        VitalyCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Dose")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)

                        Text("\(treatment.currentDose, specifier: "%.2g") mg")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.vitalyPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Week \(treatment.weeksOnCurrentDose)")
                            .font(.headline)
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Text("on this dose")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }

                // Progress to next dose
                if !treatment.isAtMaxDose {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Progress to dose increase")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)

                            Spacer()

                            Text("\(treatment.weeksOnCurrentDose)/\(treatment.medication.weeksPerDose) weeks")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.vitalyTextPrimary)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.vitalySurface)
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(treatment.isReadyForDoseIncrease ? Color.green : Color.vitalyPrimary)
                                    .frame(width: geo.size.width * min(Double(treatment.weeksOnCurrentDose) / Double(treatment.medication.weeksPerDose), 1.0), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.green)
                        Text("You're at the maximum dose")
                            .font(.subheadline)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Dose Schedule

    private func doseScheduleCard(_ treatment: GLP1Treatment) -> some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(Color.vitalyPrimary)
                    Text("DOSE ESCALATION SCHEDULE")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                Text("\(treatment.medication.displayName) - \(treatment.medication.weeksPerDose) weeks per dose")
                    .font(.caption)
                    .foregroundStyle(Color.vitalyTextSecondary)

                VStack(spacing: 0) {
                    ForEach(Array(treatment.medication.doseSchedule.enumerated()), id: \.offset) { index, dose in
                        HStack(spacing: 16) {
                            // Timeline dot
                            ZStack {
                                Circle()
                                    .fill(doseColor(dose, currentDose: treatment.currentDose))
                                    .frame(width: 16, height: 16)

                                if dose == treatment.currentDose {
                                    Circle()
                                        .stroke(Color.vitalyPrimary, lineWidth: 3)
                                        .frame(width: 24, height: 24)
                                }
                            }
                            .frame(width: 28)

                            // Dose info
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(dose, specifier: "%.2g") mg")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(dose == treatment.currentDose ? Color.vitalyPrimary : Color.vitalyTextPrimary)

                                if dose == treatment.currentDose {
                                    Text("Current dose")
                                        .font(.caption)
                                        .foregroundStyle(Color.vitalyPrimary)
                                } else if dose < treatment.currentDose {
                                    Text("Completed")
                                        .font(.caption)
                                        .foregroundStyle(Color.green)
                                }
                            }

                            Spacer()

                            // Week estimate
                            if dose > treatment.currentDose {
                                let weeksAway = (index - treatment.currentDoseIndex) * treatment.medication.weeksPerDose - treatment.weeksOnCurrentDose
                                if weeksAway > 0 {
                                    Text("~\(weeksAway) weeks")
                                        .font(.caption)
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                }
                            }
                        }
                        .padding(.vertical, 12)

                        if index < treatment.medication.doseSchedule.count - 1 {
                            HStack {
                                Rectangle()
                                    .fill(index < treatment.currentDoseIndex ? Color.green : Color.vitalySurface)
                                    .frame(width: 2, height: 20)
                                    .padding(.leading, 13)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private func doseColor(_ dose: Double, currentDose: Double) -> Color {
        if dose < currentDose {
            return .green
        } else if dose == currentDose {
            return Color.vitalyPrimary
        } else {
            return Color.vitalySurface
        }
    }

    // MARK: - Guidelines

    private var guidelinesCard: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.vitalySleep)
                    Text("GUIDELINES")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                VStack(alignment: .leading, spacing: 12) {
                    guidelineRow(icon: "clock", text: "Stay on each dose for at least 4 weeks before increasing")
                    guidelineRow(icon: "face.smiling", text: "Only increase if side effects are manageable")
                    guidelineRow(icon: "stethoscope", text: "Always consult your doctor before changing doses")
                    guidelineRow(icon: "arrow.down.circle", text: "You can decrease dose if side effects are severe")
                }
            }
            .padding(20)
        }
    }

    private func guidelineRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.vitalyTextSecondary)
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
    }

    // MARK: - Increase Dose Button

    private func increaseDoseButton(nextDose: Double) -> some View {
        Button {
            selectedNewDose = nextDose
            showingDoseUpdate = true
        } label: {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                Text("Increase to \(nextDose, specifier: "%.2g") mg")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.green)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Update Dose

    private func updateDose() {
        Task {
            do {
                try await glp1Service.updateDose(selectedNewDose)
            } catch {
                print("Error updating dose: \(error)")
            }
        }
    }
}

#Preview {
    DoseScheduleView(glp1Service: GLP1Service())
}
