import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SettingsViewModel
    @Bindable var measurementService: BodyMeasurementService
    @Bindable var glp1Service: GLP1Service
    let healthKitService: HealthKitService
    @State private var showingEditName = false
    @State private var editedName = ""
    @State private var showingAppleIdHelp = false
    @State private var showingProfileEdit = false
    @State private var showingGLP1Dashboard = false
    @State private var showingMedicalDisclaimer = false
    @State private var showingOnboardingAlert = false
    @State private var onboardingAlertMessage = ""
    private var authService: AuthService

    init(authService: AuthService, measurementService: BodyMeasurementService, healthKitService: HealthKitService, glp1Service: GLP1Service) {
        _viewModel = State(initialValue: SettingsViewModel(authService: authService))
        self.measurementService = measurementService
        self.healthKitService = healthKitService
        self.glp1Service = glp1Service
        self.authService = authService
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.vitalyBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        headerSection

                        // Profile Card
                        profileCard

                        // Body Measurements (Age & Height)
                        bodyMeasurementsCard

                        // Goals
                        goalsCard

                        // Preferences
                        preferencesCard

                        // Health Data
                        healthDataCard

                        // About
                        aboutCard

                        // Medical Disclaimer
                        medicalDisclaimerCard

                        // Beta Features
                        betaFeaturesCard

                        // Developer (Debug)
                        developerCard

                        // Sign Out
                        signOutButton

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .clipped()
            .contentShape(Rectangle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.headline)
                        .foregroundStyle(Color.vitalyTextPrimary)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $viewModel.showingSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    viewModel.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showingProfileEdit) {
                ProfileEditSheet(authService: authService)
            }
            .sheet(isPresented: $showingGLP1Dashboard) {
                GLP1DashboardView(glp1Service: glp1Service, measurementService: measurementService)
            }
            .sheet(isPresented: $showingMedicalDisclaimer) {
                MedicalDisclaimerSheet()
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("Today")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.vitalyTextPrimary)

            Spacer()

            // Profile avatar
            profileImage
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    // MARK: - Profile Card
    private var profileCard: some View {
        Button {
            if let name = viewModel.currentUser?.displayName, !name.isEmpty {
                editedName = name
                showingEditName = true
            } else {
                showingAppleIdHelp = true
            }
        } label: {
            VitalyCard {
                HStack(spacing: 16) {
                    profileImage
                        .frame(width: 64, height: 64)

                    VStack(alignment: .leading, spacing: 6) {
                        if let displayName = viewModel.currentUser?.displayName, !displayName.isEmpty {
                            Text(displayName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.vitalyTextPrimary)
                        } else {
                            Text("Tap to enter name")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.vitalyPrimary)
                        }

                        if let email = viewModel.currentUser?.email, !email.isEmpty {
                            Text(email)
                                .font(.subheadline)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        } else if let phone = viewModel.currentUser?.phoneNumber, !phone.isEmpty {
                            Text(phone)
                                .font(.subheadline)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }

                        if let createdAt = viewModel.currentUser?.createdAt {
                            Text("Member since \(createdAt, format: .dateTime.month().year())")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary.opacity(0.7))
                        }
                    }

                    Spacer()

                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.vitalyPrimary)
                }
                .padding(20)
            }
        }
        .buttonStyle(.plain)
        .alert("Enter your name", isPresented: $showingEditName) {
            TextField("Name", text: $editedName)
            Button("Save") {
                Task {
                    await viewModel.updateDisplayName(editedName)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your name will be displayed in your profile")
        }
        .alert("Get name from Apple ID", isPresented: $showingAppleIdHelp) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Enter name manually") {
                editedName = ""
                showingEditName = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Apple only sends your name the first time you sign in.\n\n1. Go to Settings → Apple ID → Sign-In & Security → Sign in with Apple → Vitaly → Stop Using\n2. Sign out and in again in the app")
        }
        .alert("Done", isPresented: $showingOnboardingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(onboardingAlertMessage)
        }
    }

    @ViewBuilder
    private var profileImage: some View {
        if let photoURL = viewModel.currentUser?.photoURL,
           let url = URL(string: photoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    profilePlaceholder
                @unknown default:
                    profilePlaceholder
                }
            }
            .clipShape(Circle())
        } else {
            profilePlaceholder
        }
    }

    private var profilePlaceholder: some View {
        Circle()
            .fill(LinearGradient.vitalyGradient)
            .overlay {
                if let initial = viewModel.currentUser?.displayName?.first ??
                               viewModel.currentUser?.phoneNumber.first {
                    Text(String(initial).uppercased())
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
    }

    // MARK: - Body Measurements Card
    private var bodyMeasurementsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BIOLOGY")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vitalyTextSecondary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            Button {
                showingProfileEdit = true
            } label: {
                VitalyCard {
                    HStack(spacing: 16) {
                        // Age
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.vitalyPrimary.opacity(0.15))
                                    .frame(width: 36, height: 36)

                                Image(systemName: "birthday.cake.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.vitalyPrimary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Age")
                                    .font(.caption)
                                    .foregroundStyle(Color.vitalyTextSecondary)
                                if let age = viewModel.currentUser?.age {
                                    Text("\(age) years")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.vitalyTextPrimary)
                                } else {
                                    Text("Not set")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                }
                            }
                        }

                        Spacer()

                        // Height
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.vitalySleep.opacity(0.15))
                                    .frame(width: 36, height: 36)

                                Image(systemName: "ruler.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.vitalySleep)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Height")
                                    .font(.caption)
                                    .foregroundStyle(Color.vitalyTextSecondary)
                                if let height = viewModel.currentUser?.heightCm {
                                    Text("\(Int(height)) cm")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.vitalyTextPrimary)
                                } else {
                                    Text("Not set")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.vitalyTextSecondary)
                                }
                            }
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                    .padding(16)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Goals Card
    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GOALS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vitalyTextSecondary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            VitalyCard {
                VStack(spacing: 0) {
                    // Steps
                    GoalPickerRow(
                        icon: "figure.walk",
                        iconColor: .vitalyActivity,
                        title: "Daily steps",
                        selection: stepsGoalBinding,
                        options: HealthGoals.stepsOptions,
                        formatter: { "\($0)" }
                    )

                    Divider()
                        .background(Color.vitalySurface)

                    // Sleep
                    GoalPickerRow(
                        icon: "bed.double.fill",
                        iconColor: .vitalySleep,
                        title: "Sleep",
                        selection: sleepGoalBinding,
                        options: HealthGoals.sleepOptions,
                        formatter: { String(format: "%.1f hours", $0) }
                    )

                    Divider()
                        .background(Color.vitalySurface)

                    // Exercise
                    GoalPickerRow(
                        icon: "flame.fill",
                        iconColor: .vitalyHeart,
                        title: "Exercise minutes",
                        selection: exerciseGoalBinding,
                        options: HealthGoals.exerciseOptions,
                        formatter: { "\($0) min" }
                    )

                    Divider()
                        .background(Color.vitalySurface)

                    // Calories
                    GoalPickerRow(
                        icon: "bolt.fill",
                        iconColor: .vitalyRecovery,
                        title: "Active calories",
                        selection: caloriesGoalBinding,
                        options: HealthGoals.caloriesOptions,
                        formatter: { "\($0) kcal" }
                    )
                }
            }
        }
    }

    // MARK: - Preferences Card
    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PREFERENCES")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vitalyTextSecondary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            VitalyCard {
                VStack(spacing: 0) {
                    SettingsToggleRow(
                        icon: "bell.fill",
                        iconColor: .vitalyPrimary,
                        title: "Notifications",
                        isOn: notificationsBinding
                    )

                    Divider()
                        .background(Color.vitalySurface)

                    SettingsToggleRow(
                        icon: "chart.bar.fill",
                        iconColor: .vitalyRecovery,
                        title: "Daily insights",
                        isOn: dailyInsightsBinding
                    )

                    Divider()
                        .background(Color.vitalySurface)

                    SettingsPickerRow(
                        icon: "ruler.fill",
                        iconColor: .vitalySleep,
                        title: "Units",
                        selection: unitsBinding
                    )
                }
            }
        }
    }

    // MARK: - Health Data Card
    private var healthDataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HEALTH DATA")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vitalyTextSecondary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            VitalyCard {
                Button {
                    viewModel.openHealthKitSettings()
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.vitalyHeart.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: "heart.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.vitalyHeart)
                        }

                        Text("HealthKit Permissions")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.vitalyTextPrimary)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                    .padding(16)
                }
            }
        }
    }

    // MARK: - About Card
    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ABOUT")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vitalyTextSecondary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            VitalyCard {
                VStack(spacing: 0) {
                    SettingsInfoRow(title: "Version", value: appVersion)

                    Divider()
                        .background(Color.vitalySurface)

                    SettingsInfoRow(title: "Build", value: buildNumber)
                }
            }
        }
    }

    // MARK: - Medical Disclaimer Card
    private var medicalDisclaimerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("IMPORTANT")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vitalyTextSecondary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            Button {
                showingMedicalDisclaimer = true
            } label: {
                VitalyCard {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.vitalyHeart.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: "exclamationmark.shield.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.vitalyHeart)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Medical Disclaimer")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.vitalyTextPrimary)

                            Text("AI-generated content, not medical advice")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                    .padding(16)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Beta Features Card
    private var betaFeaturesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text("BETA")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .tracking(1.2)

                Text("EXPERIMENTAL")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.vitalyPrimary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)

            VitalyCard {
                Button {
                    showingGLP1Dashboard = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.vitalyPrimary.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: "pills.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.vitalyPrimary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("GLP-1 Tracker")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.vitalyTextPrimary)

                            Text("Track Ozempic, Wegovy, Mounjaro")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                    }
                    .padding(16)
                }
            }
        }
    }

    // MARK: - Sign Out Button
    // MARK: - Developer Card
    private var developerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text("DEVELOPER")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .tracking(1.2)

                Text("DEBUG")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.vitalySleep)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)

            VitalyCard {
                VStack(spacing: 0) {
                    Button {
                        resetOnboarding()
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.vitalySleep.opacity(0.15))
                                    .frame(width: 36, height: 36)

                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.vitalySleep)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reset Onboarding")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.vitalyTextPrimary)

                                Text("Show onboarding on next login")
                                    .font(.caption)
                                    .foregroundStyle(Color.vitalyTextSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }
                        .padding(16)
                    }

                    Divider()
                        .background(Color.vitalyTextSecondary.opacity(0.2))

                    Button {
                        markOnboardingComplete()
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.vitalyExcellent.opacity(0.15))
                                    .frame(width: 36, height: 36)

                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.vitalyExcellent)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Skip Onboarding")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.vitalyTextPrimary)

                                Text("Mark onboarding as completed")
                                    .font(.caption)
                                    .foregroundStyle(Color.vitalyTextSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }
                        .padding(16)
                    }
                }
            }
        }
    }

    private func resetOnboarding() {
        let safeUserId = authService.currentUser?.id ?? authService.currentUser?.phoneNumber ?? ""
        if !safeUserId.isEmpty {
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding_\(safeUserId)")
            UserDefaults.standard.removeObject(forKey: "hasSeenAIDisclaimer")
            onboardingAlertMessage = "Onboarding will show on next login. Signing out..."
            showingOnboardingAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                viewModel.signOut()
            }
        }
    }

    private func markOnboardingComplete() {
        let safeUserId = authService.currentUser?.id ?? authService.currentUser?.phoneNumber ?? ""
        if !safeUserId.isEmpty {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding_\(safeUserId)")
            UserDefaults.standard.set(true, forKey: "hasSeenAIDisclaimer")
            onboardingAlertMessage = "Onboarding marked as completed!"
            showingOnboardingAlert = true
        }
    }

    private var signOutButton: some View {
        Button {
            viewModel.showingSignOutConfirmation = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16))

                Text("Sign Out")
                    .font(.headline)
            }
            .foregroundStyle(Color.vitalyHeart)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.vitalyHeart.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.vitalyHeart.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(.top, 8)
    }

    // MARK: - Bindings
    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { viewModel.currentUser?.settings.notificationsEnabled ?? true },
            set: { _ in
                Task { await viewModel.toggleNotifications() }
            }
        )
    }

    private var dailyInsightsBinding: Binding<Bool> {
        Binding(
            get: { viewModel.currentUser?.settings.dailyInsightsEnabled ?? true },
            set: { _ in
                Task { await viewModel.toggleDailyInsights() }
            }
        )
    }

    private var unitsBinding: Binding<UserSettings.UnitSystem> {
        Binding(
            get: { viewModel.currentUser?.settings.preferredUnits ?? .metric },
            set: { newValue in
                Task { await viewModel.updateUnits(newValue) }
            }
        )
    }

    private var stepsGoalBinding: Binding<Int> {
        Binding(
            get: { viewModel.currentUser?.settings.goals.dailySteps ?? 10000 },
            set: { newValue in
                Task { await viewModel.updateGoal(\.dailySteps, value: newValue) }
            }
        )
    }

    private var sleepGoalBinding: Binding<Double> {
        Binding(
            get: { viewModel.currentUser?.settings.goals.sleepHours ?? 8.0 },
            set: { newValue in
                Task { await viewModel.updateGoal(\.sleepHours, value: newValue) }
            }
        )
    }

    private var exerciseGoalBinding: Binding<Int> {
        Binding(
            get: { viewModel.currentUser?.settings.goals.exerciseMinutes ?? 30 },
            set: { newValue in
                Task { await viewModel.updateGoal(\.exerciseMinutes, value: newValue) }
            }
        )
    }

    private var caloriesGoalBinding: Binding<Int> {
        Binding(
            get: { viewModel.currentUser?.settings.goals.activeCalories ?? 500 },
            set: { newValue in
                Task { await viewModel.updateGoal(\.activeCalories, value: newValue) }
            }
        )
    }

    // MARK: - Helpers
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.vitalyTextPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.vitalyPrimary)
        }
        .padding(16)
    }
}

// MARK: - Settings Picker Row
struct SettingsPickerRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var selection: UserSettings.UnitSystem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.vitalyTextPrimary)

            Spacer()

            Picker("", selection: $selection) {
                Text("Metric").tag(UserSettings.UnitSystem.metric)
                Text("Imperial").tag(UserSettings.UnitSystem.imperial)
            }
            .pickerStyle(.menu)
            .tint(Color.vitalyPrimary)
        }
        .padding(16)
    }
}

// MARK: - Settings Info Row
struct SettingsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.vitalyTextPrimary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
        .padding(16)
    }
}

// MARK: - Goal Picker Row
struct GoalPickerRow<T: Hashable>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var selection: T
    let options: [T]
    let formatter: (T) -> String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.vitalyTextPrimary)

            Spacer()

            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(formatter(option)).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.vitalyPrimary)
        }
        .padding(16)
    }
}

// MARK: - Medical Disclaimer Sheet
struct MedicalDisclaimerSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header Icon
                        ZStack {
                            Circle()
                                .fill(Color.vitalyHeart.opacity(0.15))
                                .frame(width: 80, height: 80)

                            Image(systemName: "exclamationmark.shield.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Color.vitalyHeart)
                        }
                        .padding(.top, 20)

                        // Title
                        VStack(spacing: 8) {
                            Text("Medical Disclaimer")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Color.vitalyTextPrimary)

                            Text("Please read this important information")
                                .font(.subheadline)
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }

                        // Disclaimer Cards
                        VStack(spacing: 16) {
                            DisclaimerInfoCard(
                                icon: "brain.head.profile",
                                title: "AI-Generated Content",
                                description: "All health insights, recommendations, and analysis in this app are generated by artificial intelligence. While we strive for accuracy, AI can make mistakes and may not always provide correct information.",
                                color: Color.vitalyPrimary
                            )

                            DisclaimerInfoCard(
                                icon: "stethoscope",
                                title: "Not Medical Advice",
                                description: "The information provided by Vitaly is for informational and educational purposes only. It should NOT be considered medical advice, diagnosis, or treatment recommendation.",
                                color: Color.vitalyHeart
                            )

                            DisclaimerInfoCard(
                                icon: "person.fill.questionmark",
                                title: "Consult Healthcare Professionals",
                                description: "Always consult with qualified healthcare providers before making any decisions about your health, medications, diet, or treatment plans. Never disregard professional medical advice.",
                                color: Color.vitalySleep
                            )

                            DisclaimerInfoCard(
                                icon: "exclamationmark.triangle.fill",
                                title: "Emergency Situations",
                                description: "This app is not designed for emergency use. In case of a medical emergency, call emergency services (112) immediately. Do not rely on this app for urgent medical situations.",
                                color: Color.vitalyRecovery
                            )
                        }
                        .padding(.horizontal, 16)

                        // Summary
                        VStack(spacing: 12) {
                            Text("By using Vitaly, you acknowledge that:")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.vitalyTextPrimary)

                            VStack(alignment: .leading, spacing: 8) {
                                BulletPoint(text: "All insights are AI-generated and may contain errors")
                                BulletPoint(text: "This app does not replace professional medical advice")
                                BulletPoint(text: "You will consult healthcare providers for medical decisions")
                                BulletPoint(text: "You understand the limitations of AI health analysis")
                            }
                        }
                        .padding(20)
                        .background(Color.vitalyCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 16)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Disclaimer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.vitalyPrimary)
                }
            }
        }
    }
}

// MARK: - Disclaimer Info Card
struct DisclaimerInfoCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.vitalyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Bullet Point
struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.vitalyPrimary)
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            Text(text)
                .font(.caption)
                .foregroundStyle(Color.vitalyTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview
#Preview("Settings") {
    let authService = AuthService()
    authService.currentUser = User(
        id: "123",
        phoneNumber: "+46701234567",
        displayName: "Anna Andersson",
        photoURL: nil,
        createdAt: Date().addingTimeInterval(-86400 * 30),
        settings: UserSettings(
            notificationsEnabled: true,
            dailyInsightsEnabled: true,
            preferredUnits: .metric
        )
    )
    let measurementService = BodyMeasurementService()
    let healthKitService = HealthKitService()
    let glp1Service = GLP1Service()
    return SettingsView(authService: authService, measurementService: measurementService, healthKitService: healthKitService, glp1Service: glp1Service)
}
