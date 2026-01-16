import SwiftUI

struct GLP1DashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var glp1Service: GLP1Service
    @Bindable var measurementService: BodyMeasurementService

    @State private var showingSetup = false
    @State private var showingLogInjection = false
    @State private var showingSideEffects = false
    @State private var showingBodyComp = false
    @State private var showingDoseSchedule = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                if glp1Service.isLoading {
                    ProgressView()
                } else if glp1Service.treatment == nil {
                    noTreatmentView
                } else {
                    mainContent
                }
            }
            .navigationTitle("GLP-1 Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Color.vitalyTextSecondary)
                }

                if glp1Service.treatment != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                showingSetup = true
                            } label: {
                                Label("Edit Treatment", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                Task {
                                    try? await glp1Service.stopTreatment()
                                }
                            } label: {
                                Label("Stop Treatment", systemImage: "stop.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(Color.vitalyPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSetup) {
                GLP1SetupView(glp1Service: glp1Service, measurementService: measurementService)
            }
            .sheet(isPresented: $showingLogInjection) {
                LogInjectionView(glp1Service: glp1Service)
            }
            .sheet(isPresented: $showingSideEffects) {
                SideEffectsLogView(glp1Service: glp1Service)
            }
            .sheet(isPresented: $showingBodyComp) {
                BodyCompositionView(glp1Service: glp1Service)
            }
            .sheet(isPresented: $showingDoseSchedule) {
                DoseScheduleView(glp1Service: glp1Service)
            }
        }
    }

    // MARK: - No Treatment View

    private var noTreatmentView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "pills.circle")
                .font(.system(size: 80))
                .foregroundStyle(Color.vitalyPrimary)

            VStack(spacing: 8) {
                Text("GLP-1 Tracker")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text("Track your weight loss medication,\nmonitor progress, and log side effects")
                    .font(.subheadline)
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                showingSetup = true
            } label: {
                Text("Start Tracking")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(LinearGradient.vitalyGradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Treatment Status Card
                treatmentStatusCard

                // Quick Actions
                quickActionsSection

                // Weight Progress
                weightProgressSection

                // Side Effects Summary
                sideEffectsSummary

                // Recent Activity
                recentActivitySection
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Treatment Status Card

    private var treatmentStatusCard: some View {
        VitalyCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(glp1Service.treatment?.medication.displayName ?? "")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Text("\(glp1Service.treatment?.currentDose ?? 0, specifier: "%.2g") mg")
                            .font(.title3)
                            .foregroundStyle(Color.vitalyPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Week \(glp1Service.treatment?.weeksOnTreatment ?? 0)")
                            .font(.headline)
                            .foregroundStyle(Color.vitalyTextPrimary)

                        if let treatment = glp1Service.treatment, treatment.isReadyForDoseIncrease {
                            Text("Ready for increase")
                                .font(.caption)
                                .foregroundStyle(Color.green)
                        }
                    }
                }

                Divider()
                    .background(Color.vitalySurface)

                // Injection Status
                HStack {
                    if glp1Service.isInjectionDue {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(Color.vitalyPrimary)
                        Text("Injection due")
                            .foregroundStyle(Color.vitalyPrimary)
                    } else if let days = glp1Service.daysSinceLastInjection {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.green)
                        Text("\(days) days since last injection")
                            .foregroundStyle(Color.vitalyTextSecondary)
                    } else {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(Color.vitalyTextSecondary)
                        Text("No injections logged")
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }

                    Spacer()

                    Button {
                        showingLogInjection = true
                    } label: {
                        Text("Log")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.vitalyPrimary)
                            .clipShape(Capsule())
                    }
                }
                .font(.subheadline)
            }
            .padding(20)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            quickActionButton(
                icon: "syringe",
                title: "Log Injection",
                color: Color.vitalyPrimary
            ) {
                showingLogInjection = true
            }

            quickActionButton(
                icon: "face.smiling",
                title: "Side Effects",
                color: Color.vitalySleep
            ) {
                showingSideEffects = true
            }

            quickActionButton(
                icon: "figure.arms.open",
                title: "Body Comp",
                color: Color.vitalyActivity
            ) {
                showingBodyComp = true
            }

            quickActionButton(
                icon: "chart.line.uptrend.xyaxis",
                title: "Dose Plan",
                color: Color.green
            ) {
                showingDoseSchedule = true
            }
        }
    }

    private func quickActionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VitalyCard(cornerRadius: 16) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(color)

                    Text(title)
                        .font(.caption)
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Weight Progress Section

    private var weightProgressSection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "scalemass")
                        .foregroundStyle(Color.vitalyPrimary)
                    Text("WEIGHT PROGRESS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                if let treatment = glp1Service.treatment,
                   let currentWeight = measurementService.latestWeight {
                    let stats = WeightLossStats(
                        startWeight: treatment.startWeight,
                        currentWeight: currentWeight,
                        targetWeight: treatment.targetWeight,
                        weeksOnTreatment: treatment.weeksOnTreatment
                    )

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.1f kg", stats.totalLost))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.vitalyTextPrimary)

                            Text("total lost")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 8) {
                            statRow(label: "Start", value: String(format: "%.1f kg", stats.startWeight))
                            statRow(label: "Current", value: String(format: "%.1f kg", stats.currentWeight))
                            if let target = stats.targetWeight {
                                statRow(label: "Target", value: String(format: "%.1f kg", target))
                            }
                        }
                    }

                    // Progress bar if target set
                    if let progress = stats.progressToTarget {
                        VStack(alignment: .leading, spacing: 4) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.vitalySurface)
                                        .frame(height: 8)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.vitalyPrimary)
                                        .frame(width: geo.size.width * min(progress / 100, 1.0), height: 8)
                                }
                            }
                            .frame(height: 8)

                            Text(String(format: "%.0f%% to goal", progress))
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }
                        .padding(.top, 8)
                    }

                    // Status message
                    HStack {
                        Image(systemName: stats.isLosingTooFast ? "exclamationmark.triangle.fill" :
                                stats.isLosingTooSlow ? "tortoise.fill" : "checkmark.circle.fill")
                            .foregroundStyle(stats.isLosingTooFast ? Color.yellow :
                                    stats.isLosingTooSlow ? Color.vitalyTextSecondary : Color.green)

                        Text(stats.statusMessage)
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                    .padding(.top, 4)

                } else {
                    Text("Log your current weight to see progress")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextSecondary)
                }
            }
            .padding(20)
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.vitalyTextSecondary)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.vitalyTextPrimary)
        }
    }

    // MARK: - Side Effects Summary

    private var sideEffectsSummary: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "heart.text.square")
                        .foregroundStyle(Color.vitalySleep)
                    Text("SIDE EFFECTS (7-DAY AVG)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)

                    Spacer()

                    Button {
                        showingSideEffects = true
                    } label: {
                        Text("Log")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.vitalyPrimary)
                    }
                }

                if glp1Service.sideEffectLogs.isEmpty {
                    Text("No side effects logged yet")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextSecondary)
                } else {
                    HStack(spacing: 24) {
                        sideEffectGauge(
                            label: "Nausea",
                            value: glp1Service.averageNausea,
                            color: nauseaColor(glp1Service.averageNausea)
                        )

                        sideEffectGauge(
                            label: "Energy",
                            value: glp1Service.averageEnergy,
                            color: energyColor(glp1Service.averageEnergy)
                        )
                    }
                }
            }
            .padding(20)
        }
    }

    private func sideEffectGauge(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.vitalySurface, lineWidth: 6)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: value / 10)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))

                Text(String(format: "%.1f", value))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.vitalyTextPrimary)
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
    }

    private func nauseaColor(_ value: Double) -> Color {
        if value <= 3 { return .green }
        if value <= 6 { return .yellow }
        return .red
    }

    private func energyColor(_ value: Double) -> Color {
        if value >= 7 { return .green }
        if value >= 4 { return .yellow }
        return .red
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VitalyCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(Color.vitalyActivity)
                    Text("RECENT ACTIVITY")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .tracking(1.2)
                }

                if glp1Service.medicationLogs.isEmpty && glp1Service.sideEffectLogs.isEmpty {
                    Text("No activity yet")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextSecondary)
                } else {
                    VStack(spacing: 12) {
                        ForEach(glp1Service.medicationLogs.prefix(3)) { log in
                            activityRow(
                                icon: "syringe",
                                color: Color.vitalyPrimary,
                                title: String(format: "%.2g mg injection", log.dose),
                                date: log.date
                            )
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private func activityRow(icon: String, color: Color, title: String, date: Date) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.15))
                .clipShape(Circle())

            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.vitalyTextPrimary)

            Spacer()

            Text(date, format: .dateTime.month().day())
                .font(.caption)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    GLP1DashboardView(
        glp1Service: GLP1Service(),
        measurementService: BodyMeasurementService()
    )
}
