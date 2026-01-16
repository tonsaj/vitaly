import SwiftUI

/// Example views demonstrating different wavy header styles
struct WavyHeaderExamplesView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Full Wavy Header") {
                    NavigationLink("Dashboard Style") {
                        DashboardStyleExample()
                    }
                }

                Section("Compact Headers") {
                    NavigationLink("Profile Header") {
                        ProfileStyleExample()
                    }

                    NavigationLink("Settings Header") {
                        SettingsStyleExample()
                    }
                }

                Section("Decorative Elements") {
                    NavigationLink("Wave Dividers") {
                        DividerStyleExample()
                    }
                }
            }
            .navigationTitle("Wavy Header Examples")
        }
    }
}

// MARK: - Dashboard Style Example
struct DashboardStyleExample: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                WavyHeaderView(
                    title: "Idag",
                    subtitle: "Torsdag, 12 januari 2026"
                )

                VStack(spacing: 16) {
                    ForEach(0..<5, id: \.self) { _ in
                        VitalyCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "heart.fill")
                                        .foregroundStyle(Color.vitalyHeart)
                                    Text("Sample Card")
                                        .font(.headline)
                                        .foregroundStyle(Color.vitalyTextPrimary)
                                }

                                Text("This is sample content to show how the wavy header looks with scrollable content.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.vitalyTextSecondary)
                            }
                            .padding(16)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
        }
        .background(Color.vitalyBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Profile Style Example
struct ProfileStyleExample: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                CompactWavyHeader(title: "Profil")

                VStack(spacing: 20) {
                    // Profile Picture
                    ZStack {
                        Circle()
                            .fill(LinearGradient.vitalyGradient)
                            .frame(width: 120, height: 120)

                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 20)

                    Text("Anna Andersson")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Text("anna@example.com")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextSecondary)

                    // Profile Stats
                    HStack(spacing: 40) {
                        StatItem(label: "Days", value: "127")
                        StatItem(label: "Steps", value: "8.5k")
                        StatItem(label: "Sleep", value: "7.2h")
                    }
                    .padding(.top, 20)

                    // Profile Options
                    VStack(spacing: 12) {
                        ProfileOption(icon: "person.fill", title: "Redigera profil")
                        ProfileOption(icon: "bell.fill", title: "Notifikationer")
                        ProfileOption(icon: "lock.fill", title: "Sekretess")
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color.vitalyBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Settings Style Example
struct SettingsStyleExample: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                CompactWavyHeader(title: "Inställningar")

                VStack(spacing: 24) {
                    SettingsSection(title: "Allmänt") {
                        SettingRow(icon: "person.circle", title: "Konto", value: "Anna A.")
                        SettingRow(icon: "globe", title: "Språk", value: "Svenska")
                        SettingRow(icon: "paintbrush", title: "Tema", value: "Mörkt")
                    }

                    SettingsSection(title: "Hälsa") {
                        SettingRow(icon: "heart.fill", title: "HealthKit", value: "Ansluten")
                        SettingRow(icon: "bell.fill", title: "Påminnelser", value: "På")
                        SettingRow(icon: "chart.line.uptrend.xyaxis", title: "Datasynk", value: "Automatisk")
                    }

                    SettingsSection(title: "Om") {
                        SettingRow(icon: "info.circle", title: "Version", value: "1.0.0")
                        SettingRow(icon: "doc.text", title: "Användarvillkor", value: "")
                        SettingRow(icon: "lock.shield", title: "Integritet", value: "")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .background(Color.vitalyBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Divider Style Example
struct DividerStyleExample: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                CompactWavyHeader(title: "Sections")

                VStack(spacing: 0) {
                    // Section 1
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Morgon")
                            .font(.title2.bold())
                            .foregroundStyle(Color.vitalyTextPrimary)

                        VitalyCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "sunrise.fill")
                                        .foregroundStyle(Color.vitalyActivity)
                                    Text("Morgonrutin")
                                        .font(.headline)
                                        .foregroundStyle(Color.vitalyTextPrimary)
                                }
                                Text("Start dagen med en promenad och frukost.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.vitalyTextSecondary)
                            }
                            .padding(16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Wave Divider
                    WavyDivider(height: 50)
                        .padding(.vertical, 20)

                    // Section 2
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Middag")
                            .font(.title2.bold())
                            .foregroundStyle(Color.vitalyTextPrimary)

                        VitalyCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "sun.max.fill")
                                        .foregroundStyle(Color.vitalyRecovery)
                                    Text("Lunchaktivitet")
                                        .font(.headline)
                                        .foregroundStyle(Color.vitalyTextPrimary)
                                }
                                Text("En kort promenad efter lunch.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.vitalyTextSecondary)
                            }
                            .padding(16)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Wave Divider
                    WavyDivider(height: 50)
                        .padding(.vertical, 20)

                    // Section 3
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Kväll")
                            .font(.title2.bold())
                            .foregroundStyle(Color.vitalyTextPrimary)

                        VitalyCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "moon.stars.fill")
                                        .foregroundStyle(Color.vitalySleep)
                                    Text("Kvällsrutin")
                                        .font(.headline)
                                        .foregroundStyle(Color.vitalyTextPrimary)
                                }
                                Text("Varva ner och förbered dig för sömn.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.vitalyTextSecondary)
                            }
                            .padding(16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(Color.vitalyBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting Views
struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.vitalyTextPrimary)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
    }
}

struct ProfileOption: View {
    let icon: String
    let title: String

    var body: some View {
        VitalyCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.vitalyPrimary.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(Color.vitalyPrimary)
                }

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.vitalyTextSecondary)
            }
            .padding(16)
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.vitalyTextSecondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.vitalyPrimary)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(Color.vitalyTextPrimary)

            Spacer()

            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.vitalyTextSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.vitalyCardBackground)
    }
}

// MARK: - Preview
#Preview {
    WavyHeaderExamplesView()
        .preferredColorScheme(.dark)
}
