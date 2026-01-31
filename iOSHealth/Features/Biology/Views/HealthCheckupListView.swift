import SwiftUI

struct HealthCheckupListView: View {
    let healthCheckupService: HealthCheckupService
    @Environment(\.dismiss) private var dismiss
    @State private var showingUpload = false
    @State private var checkupToDelete: HealthCheckup?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                Group {
                    if healthCheckupService.isLoading && healthCheckupService.checkups.isEmpty {
                        loadingState
                    } else if healthCheckupService.checkups.isEmpty {
                        emptyState
                    } else {
                        checkupList
                    }
                }
            }
            .navigationTitle("Health Checkups")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Color.vitalyTextSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingUpload = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.vitalyPrimary)
                    }
                    .accessibilityLabel("Add health checkup")
                    .accessibilityHint("Opens the upload screen to add a new lab report")
                }
            }
            .sheet(isPresented: $showingUpload) {
                HealthCheckupUploadView(healthCheckupService: healthCheckupService)
            }
            .alert("Delete Checkup", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    checkupToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let checkup = checkupToDelete {
                        deleteCheckup(checkup)
                    }
                }
            } message: {
                if let checkup = checkupToDelete {
                    Text("Are you sure you want to delete \"\(checkup.title)\"? This action cannot be undone.")
                }
            }
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color.vitalyPrimary)
                .scaleEffect(1.2)

            Text("Loading checkups...")
                .font(.subheadline)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 56))
                .foregroundStyle(Color.vitalyTextSecondary.opacity(0.5))

            VStack(spacing: 8) {
                Text("No Health Checkups")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text("Upload a lab report or health checkup to track your biomarkers over time.")
                    .font(.subheadline)
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                showingUpload = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Checkup")
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.vitalyPrimary, in: Capsule())
            }
            .padding(.top, 4)
            .accessibilityLabel("Add health checkup")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Checkup List

    private var checkupList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(healthCheckupService.checkups) { checkup in
                    NavigationLink {
                        HealthCheckupDetailView(checkup: checkup)
                    } label: {
                        checkupRow(checkup)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            checkupToDelete = checkup
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .clipped()
        .contentShape(Rectangle())
        .refreshable {
            await healthCheckupService.fetchCheckups()
        }
    }

    // MARK: - Checkup Row

    private func checkupRow(_ checkup: HealthCheckup) -> some View {
        HStack(spacing: 14) {
            // Date circle
            VStack(spacing: 2) {
                Text(dayString(from: checkup.date))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text(monthString(from: checkup.date))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .textCase(.uppercase)
            }
            .frame(width: 48, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.vitalyPrimary.opacity(0.12))
            )

            // Title and details
            VStack(alignment: .leading, spacing: 4) {
                Text(checkup.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label("\(checkup.labValues.count) values", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundStyle(Color.vitalyTextSecondary)

                    if let provider = checkup.provider, !provider.isEmpty {
                        Text(provider)
                            .font(.caption)
                            .foregroundStyle(Color.vitalyTextSecondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Out of range badge + chevron
            HStack(spacing: 10) {
                if checkup.outOfRangeCount > 0 {
                    Text("\(checkup.outOfRangeCount)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 24, minHeight: 24)
                        .background(Color.vitalyHeart, in: Circle())
                        .accessibilityLabel("\(checkup.outOfRangeCount) out of range")
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextSecondary.opacity(0.5))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(checkup.title), \(checkup.formattedDate), \(checkup.labValues.count) lab values\(checkup.outOfRangeCount > 0 ? ", \(checkup.outOfRangeCount) out of range" : "")")
        .accessibilityHint("Tap to view details")
    }

    // MARK: - Helpers

    private func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    private func deleteCheckup(_ checkup: HealthCheckup) {
        Task {
            do {
                try await healthCheckupService.deleteCheckup(checkup)
            } catch {
                print("Failed to delete checkup: \(error.localizedDescription)")
            }
            checkupToDelete = nil
        }
    }
}

// MARK: - Preview

#Preview {
    HealthCheckupListView(healthCheckupService: HealthCheckupService())
        .preferredColorScheme(.dark)
}
