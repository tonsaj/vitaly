import SwiftUI

struct BodyMeasurementView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var measurementService: BodyMeasurementService
    let healthKitService: HealthKitService

    @State private var selectedDate: Date = Date()
    @State private var weightText: String = ""
    @State private var waistText: String = ""
    @State private var showingSaveConfirmation = false
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Date Picker
                        dateSection

                        // Weight Input
                        weightSection

                        // Waist Input
                        waistSection

                        // Save Button
                        saveButton

                        // History
                        historySection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Body Measurements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.vitalyPrimary)
                }
            }
            .onAppear {
                loadExistingData()
            }
            .onChange(of: selectedDate) { _, _ in
                loadExistingData()
            }
        }
    }

    // MARK: - Date Section
    private var dateSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(Color.vitalyPrimary)
                    Text("Date")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.vitalyTextPrimary)
                    Spacer()
                }

                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Color.vitalyPrimary)
            }
            .padding(16)
        }
    }

    // MARK: - Weight Section
    private var weightSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.vitalyActivity.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.vitalyActivity)
                    }

                    Text("Weight")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Spacer()

                    if let latest = measurementService.latestWeight, weightText.isEmpty {
                        Text("Last: \(String(format: "%.1f", latest)) kg")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }

                HStack {
                    TextField("0.0", text: $weightText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Text("kg")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
                .padding(.vertical, 8)
            }
            .padding(16)
        }
    }

    // MARK: - Waist Section
    private var waistSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.vitalySleep.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: "figure.arms.open")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.vitalySleep)
                    }

                    Text("Waist")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Spacer()

                    if let latest = measurementService.latestWaist, waistText.isEmpty {
                        Text("Last: \(String(format: "%.0f", latest)) cm")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                }

                HStack {
                    TextField("0", text: $waistText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Text("cm")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
                .padding(.vertical, 8)
            }
            .padding(16)
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            Task {
                await saveMeasurement()
            }
        } label: {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save Measurement")
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(canSave ? LinearGradient.vitalyGradient : LinearGradient(colors: [Color.gray], startPoint: .leading, endPoint: .trailing))
            )
        }
        .disabled(!canSave || isSaving)
    }

    // MARK: - History Section
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HISTORY")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vitalyTextSecondary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            if measurementService.measurements.isEmpty {
                VitalyCard {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.largeTitle)
                                .foregroundStyle(Color.vitalyTextSecondary.opacity(0.5))
                            Text("No measurements yet")
                                .font(.subheadline)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }
                        .padding(.vertical, 24)
                        Spacer()
                    }
                }
            } else {
                VitalyCard {
                    VStack(spacing: 0) {
                        ForEach(Array(measurementService.measurements.prefix(10).enumerated()), id: \.element.id) { index, measurement in
                            historyRow(measurement)

                            if index < min(9, measurementService.measurements.count - 1) {
                                Divider()
                                    .background(Color.vitalySurface)
                            }
                        }
                    }
                }
            }
        }
        .padding(.bottom, 40)
    }

    private func historyRow(_ measurement: BodyMeasurement) -> some View {
        HStack {
            Text(measurement.date, format: .dateTime.day().month())
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.vitalyTextPrimary)

            Spacer()

            if let weight = measurement.weight {
                HStack(spacing: 4) {
                    Image(systemName: "scalemass.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.vitalyActivity)
                    Text(String(format: "%.1f kg", weight))
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }

            if measurement.weight != nil && measurement.waistCircumference != nil {
                Text("•")
                    .foregroundStyle(Color.vitalyTextSecondary.opacity(0.5))
            }

            if let waist = measurement.waistCircumference {
                HStack(spacing: 4) {
                    Image(systemName: "figure.arms.open")
                        .font(.caption2)
                        .foregroundStyle(Color.vitalySleep)
                    Text(String(format: "%.0f cm", waist))
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
        }
        .padding(16)
    }

    // MARK: - Helpers
    private var canSave: Bool {
        let weight = Double(weightText.replacingOccurrences(of: ",", with: "."))
        let waist = Double(waistText.replacingOccurrences(of: ",", with: "."))
        return weight != nil || waist != nil
    }

    private func loadExistingData() {
        if let existing = measurementService.getMeasurement(for: selectedDate) {
            if let weight = existing.weight {
                weightText = String(format: "%.1f", weight)
            } else {
                weightText = ""
            }
            if let waist = existing.waistCircumference {
                waistText = String(format: "%.0f", waist)
            } else {
                waistText = ""
            }
        } else {
            weightText = ""
            waistText = ""
        }
    }

    private func saveMeasurement() async {
        isSaving = true
        defer { isSaving = false }

        let weight = Double(weightText.replacingOccurrences(of: ",", with: "."))
        let waist = Double(waistText.replacingOccurrences(of: ",", with: "."))

        let measurement = BodyMeasurement(
            date: selectedDate,
            weight: weight,
            waistCircumference: waist
        )

        do {
            try await measurementService.saveMeasurement(measurement)
            showingSaveConfirmation = true
        } catch {
            // Error handling
        }
    }
}

#Preview {
    BodyMeasurementView(
        measurementService: BodyMeasurementService(),
        healthKitService: HealthKitService()
    )
}
