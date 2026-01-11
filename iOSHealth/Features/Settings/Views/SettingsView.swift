import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SettingsViewModel

    init(authService: AuthService) {
        _viewModel = State(initialValue: SettingsViewModel(authService: authService))
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

                        // Preferences
                        preferencesCard

                        // Health Data
                        healthDataCard

                        // About
                        aboutCard

                        // Sign Out
                        signOutButton

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Inställningar")
                        .font(.headline)
                        .foregroundStyle(Color.vitalyTextPrimary)
                }
            }
            .alert("Fel", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .confirmationDialog(
                "Logga ut",
                isPresented: $viewModel.showingSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Logga ut", role: .destructive) {
                    viewModel.signOut()
                }
                Button("Avbryt", role: .cancel) {}
            } message: {
                Text("Är du säker på att du vill logga ut?")
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("Idag")
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
        VitalyCard {
            HStack(spacing: 16) {
                profileImage
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 6) {
                    if let displayName = viewModel.currentUser?.displayName {
                        Text(displayName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.vitalyTextPrimary)
                    } else {
                        Text("Användare")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.vitalyTextPrimary)
                    }

                    Text(viewModel.currentUser?.phoneNumber ?? "")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextSecondary)

                    if let createdAt = viewModel.currentUser?.createdAt {
                        Text("Medlem sedan \(createdAt, format: .dateTime.month().year())")
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary.opacity(0.7))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.vitalyTextSecondary)
            }
            .padding(20)
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

    // MARK: - Preferences Card
    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("INSTÄLLNINGAR")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.vitalyTextSecondary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            VitalyCard {
                VStack(spacing: 0) {
                    SettingsToggleRow(
                        icon: "bell.fill",
                        iconColor: .vitalyPrimary,
                        title: "Notifikationer",
                        isOn: notificationsBinding
                    )

                    Divider()
                        .background(Color.vitalySurface)

                    SettingsToggleRow(
                        icon: "chart.bar.fill",
                        iconColor: .vitalyRecovery,
                        title: "Dagliga insikter",
                        isOn: dailyInsightsBinding
                    )

                    Divider()
                        .background(Color.vitalySurface)

                    SettingsPickerRow(
                        icon: "ruler.fill",
                        iconColor: .vitalySleep,
                        title: "Enheter",
                        selection: unitsBinding
                    )
                }
            }
        }
    }

    // MARK: - Health Data Card
    private var healthDataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HÄLSODATA")
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

                        Text("HealthKit-behörigheter")
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
            Text("OM")
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

    // MARK: - Sign Out Button
    private var signOutButton: some View {
        Button {
            viewModel.showingSignOutConfirmation = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16))

                Text("Logga ut")
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
                Text("Metriskt").tag(UserSettings.UnitSystem.metric)
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
    return SettingsView(authService: authService)
}
