import SwiftUI

struct GLP1SetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var glp1Service: GLP1Service
    @Bindable var measurementService: BodyMeasurementService

    @State private var selectedMedication: GLP1Medication = .ozempic
    @State private var startDate = Date()
    @State private var startWeight: String = ""
    @State private var targetWeight: String = ""
    @State private var currentDose: Double = 0.25
    @State private var preferredDay: Int = 1
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var notificationsEnabled = true
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Medication Selection
                        medicationSection

                        // Treatment Details
                        treatmentDetailsSection

                        // Weight Goals
                        weightGoalsSection

                        // Injection Day (for weekly meds)
                        if selectedMedication.isWeekly {
                            injectionDaySection
                        }

                        // Reminder Settings
                        reminderSection
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
                            Text("Save Treatment")
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
                    .background(
                        LinearGradient(
                            colors: [Color.vitalyBackground.opacity(0), Color.vitalyBackground],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                        .allowsHitTesting(false)
                    )
                }
            }
            .navigationTitle("Start Treatment")
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
                loadExistingTreatment()
            }
        }
    }

    private var isValid: Bool {
        guard let weight = Double(startWeight), weight > 0 else { return false }
        return true
    }

    // MARK: - Medication Section

    private var medicationSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "pills")
                        .foregroundStyle(Color.vitalyPrimary)
                    Text("MEDICATION")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                VStack(spacing: 8) {
                    ForEach(GLP1Medication.allCases, id: \.self) { med in
                        Button {
                            selectedMedication = med
                            currentDose = med.doseSchedule.first ?? 0.25
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(med.displayName)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.vitalyTextPrimary)

                                    Text("\(med.activeIngredient) • \(med.manufacturer)")
                                        .font(.caption)
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                }

                                Spacer()

                                Image(systemName: selectedMedication == med ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedMedication == med ? Color.vitalyPrimary : Color.vitalyTextSecondary)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedMedication == med ? Color.vitalyPrimary.opacity(0.1) : Color.vitalySurface)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Treatment Details

    private var treatmentDetailsSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.vitalyPrimary)
                    Text("TREATMENT DETAILS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                // Start Date
                HStack {
                    Text("Start Date")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Spacer()

                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                        .tint(Color.vitalyPrimary)
                }

                Divider()
                    .background(Color.vitalySurface)

                // Starting Dose
                VStack(alignment: .leading, spacing: 8) {
                    Text("Starting Dose")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextPrimary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedMedication.doseSchedule, id: \.self) { dose in
                                Button {
                                    currentDose = dose
                                } label: {
                                    Text("\(dose, specifier: "%.2g") mg")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(currentDose == dose ? .white : Color.vitalyTextPrimary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(currentDose == dose ? Color.vitalyPrimary : Color.vitalySurface)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Weight Goals

    private var weightGoalsSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "scalemass")
                        .foregroundStyle(Color.vitalyPrimary)
                    Text("WEIGHT")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                // Start Weight
                VStack(alignment: .leading, spacing: 8) {
                    Text("Starting Weight *")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextPrimary)

                    HStack {
                        TextField("0.0", text: $startWeight)
                            .keyboardType(.decimalPad)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Text("kg")
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                    .padding()
                    .background(Color.vitalySurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Target Weight
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Weight (optional)")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextPrimary)

                    HStack {
                        TextField("0.0", text: $targetWeight)
                            .keyboardType(.decimalPad)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Text("kg")
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                    .padding()
                    .background(Color.vitalySurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(20)
        }
    }

    // MARK: - Injection Day

    private var injectionDaySection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "syringe")
                        .foregroundStyle(Color.vitalyPrimary)
                    Text("INJECTION DAY")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                Text("Which day do you take your injection?")
                    .font(.subheadline)
                    .foregroundStyle(Color.vitalyTextSecondary)

                HStack(spacing: 8) {
                    ForEach(1...7, id: \.self) { day in
                        Button {
                            preferredDay = day
                        } label: {
                            Text(dayName(day))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(preferredDay == day ? .white : Color.vitalyTextPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(preferredDay == day ? Color.vitalyPrimary : Color.vitalySurface)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
    }

    private func dayName(_ day: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[day - 1]
    }

    // MARK: - Reminder Section

    private var reminderSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "bell")
                        .foregroundStyle(Color.vitalyPrimary)
                    Text("REMINDER")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                // Notification Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Injection Reminder")
                            .font(.subheadline)
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Text("Get notified when it's time to inject")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $notificationsEnabled)
                        .labelsHidden()
                        .tint(Color.vitalyPrimary)
                }

                if notificationsEnabled {
                    Divider()
                        .background(Color.vitalySurface)

                    // Time Picker
                    HStack {
                        Text("Reminder Time")
                            .font(.subheadline)
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Spacer()

                        DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .tint(Color.vitalyPrimary)
                    }

                    Text(selectedMedication.isWeekly ?
                         "You'll be reminded every \(dayFullName(preferredDay)) at this time" :
                         "You'll be reminded every day at this time")
                        .font(.caption)
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
            .padding(20)
        }
    }

    private func dayFullName(_ day: Int) -> String {
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return days[day - 1]
    }

    // MARK: - Actions

    private func loadExistingTreatment() {
        if let treatment = glp1Service.treatment {
            selectedMedication = treatment.medication
            startDate = treatment.startDate
            startWeight = String(format: "%.1f", treatment.startWeight)
            if let target = treatment.targetWeight {
                targetWeight = String(format: "%.1f", target)
            }
            currentDose = treatment.currentDose
            preferredDay = treatment.preferredInjectionDay ?? 1
            notificationsEnabled = treatment.notificationsEnabled

            // Load reminder time
            var components = DateComponents()
            components.hour = treatment.preferredInjectionHour
            components.minute = treatment.preferredInjectionMinute
            if let time = Calendar.current.date(from: components) {
                reminderTime = time
            }
        } else if let weight = measurementService.latestWeight {
            startWeight = String(format: "%.1f", weight)
        }
    }

    private func saveAndDismiss() {
        guard let weight = Double(startWeight) else { return }

        isSaving = true

        // Extract hour and minute from reminder time
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: reminderTime)
        let minute = calendar.component(.minute, from: reminderTime)

        let treatment = GLP1Treatment(
            medication: selectedMedication,
            startDate: startDate,
            startWeight: weight,
            targetWeight: Double(targetWeight),
            currentDose: currentDose,
            currentDoseStartDate: startDate,
            preferredInjectionDay: selectedMedication.isWeekly ? preferredDay : nil,
            preferredInjectionHour: hour,
            preferredInjectionMinute: minute,
            notificationsEnabled: notificationsEnabled
        )

        Task {
            do {
                try await glp1Service.saveTreatment(treatment)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error saving treatment: \(error)")
                isSaving = false
            }
        }
    }
}

#Preview {
    GLP1SetupView(
        glp1Service: GLP1Service(),
        measurementService: BodyMeasurementService()
    )
}
