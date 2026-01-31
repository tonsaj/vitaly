import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Transferable Image

struct PickableImage: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            PickableImage(data: data)
        }
    }
}

// MARK: - Document Picker Representable

struct DocumentPicker: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}

// MARK: - Camera Picker Representable

struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, dismiss: dismiss)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        let dismiss: DismissAction

        init(onCapture: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

// MARK: - Upload View

struct HealthCheckupUploadView: View {
    let healthCheckupService: HealthCheckupService

    @Environment(\.dismiss) private var dismiss

    // Upload state
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showDocumentPicker = false
    @State private var showCamera = false

    // Processing state
    @State private var isProcessing = false
    @State private var processingMessage = "Analyzing document..."
    @State private var errorMessage: String?

    // Parsed result state
    @State private var parsedCheckup: HealthCheckup?
    @State private var editableTitle: String = ""
    @State private var editableDate: Date = Date()
    @State private var editableProvider: String = ""

    // Save state
    @State private var isSaving = false

    private var hasResult: Bool { parsedCheckup != nil }

    var body: some View {
        NavigationView {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                if isProcessing {
                    processingView
                } else if let checkup = parsedCheckup {
                    parsedResultView(checkup: checkup)
                } else {
                    uploadSelectionView
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.vitalyTextSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if hasResult {
                        Button("Save") {
                            saveCheckup()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.vitalyPrimary)
                        .disabled(isSaving)
                    }
                }
            }
            .navigationTitle("Upload Checkup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(contentTypes: [.pdf, .image]) { url in
                handleDocumentSelection(url: url)
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                handleCameraImage(image)
            }
            .ignoresSafeArea()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            if let newItem {
                handlePhotoSelection(item: newItem)
            }
        }
        .alert("Error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    // MARK: - Upload Selection View

    private var uploadSelectionView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Header illustration
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(Color.vitalyPrimary)
                        .padding(.top, 32)

                    Text("Upload Lab Results")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.vitalyTextPrimary)

                    Text("Take a photo or upload a PDF of your health checkup. Our AI will extract and organize your lab values automatically.")
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 8)

                // Camera button
                Button {
                    showCamera = true
                } label: {
                    uploadButtonContent(
                        icon: "camera.fill",
                        title: "Take Photo",
                        subtitle: "Use your camera to capture lab results",
                        gradient: LinearGradient(
                            colors: [Color.vitalyPrimary, Color.vitalyPrimary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }

                // Photo library picker
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    uploadButtonContent(
                        icon: "photo.fill",
                        title: "Choose from Library",
                        subtitle: "Select an image from your photo library",
                        gradient: LinearGradient(
                            colors: [Color.vitalyActivity, Color.vitalyActivity.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }

                // Files picker button (PDF + images)
                Button {
                    showDocumentPicker = true
                } label: {
                    uploadButtonContent(
                        icon: "folder.fill",
                        title: "Choose from Files",
                        subtitle: "Select a PDF or image from Files",
                        gradient: LinearGradient(
                            colors: [Color.vitalySleep, Color.vitalySleep.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }

                // Tips section
                tipsCard

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .clipped()
        .contentShape(Rectangle())
    }

    private func uploadButtonContent(
        icon: String,
        title: String,
        subtitle: String,
        gradient: LinearGradient
    ) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(20)
        .background(gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tips for best results", systemImage: "lightbulb.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.vitalyRecovery)

            VStack(alignment: .leading, spacing: 8) {
                tipRow(text: "Ensure the document is well-lit and in focus")
                tipRow(text: "Include the full page with all lab values")
                tipRow(text: "PDF format typically gives the best results")
                tipRow(text: "Reference ranges help identify abnormal values")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.vitalyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private func tipRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(Color.vitalyExcellent)
                .padding(.top, 2)

            Text(text)
                .font(.caption)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.vitalyPrimary)

            VStack(spacing: 8) {
                Text(processingMessage)
                    .font(.headline)
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text("This may take a few seconds")
                    .font(.subheadline)
                    .foregroundStyle(Color.vitalyTextSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Parsed Result View

    private func parsedResultView(checkup: HealthCheckup) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Success header
                successHeader(checkup: checkup)

                // Editable metadata card
                metadataCard

                // AI Summary
                if let summary = checkup.aiSummary, !summary.isEmpty {
                    aiSummaryCard(summary: summary)
                }

                // Lab values grouped by category
                ForEach(checkup.categories, id: \.self) { category in
                    categoryCard(
                        category: category,
                        values: checkup.labValues.filter { $0.category == category }
                    )
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .scrollBounceBehavior(.basedOnSize)
        .clipped()
        .contentShape(Rectangle())
    }

    private func successHeader(checkup: HealthCheckup) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.vitalyExcellent)

            Text("Document Parsed")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.vitalyTextPrimary)

            HStack(spacing: 16) {
                statBadge(
                    value: "\(checkup.labValues.count)",
                    label: "Lab Values",
                    color: Color.vitalyPrimary
                )
                statBadge(
                    value: "\(checkup.categories.count)",
                    label: "Categories",
                    color: Color.vitalySleep
                )
                if checkup.outOfRangeCount > 0 {
                    statBadge(
                        value: "\(checkup.outOfRangeCount)",
                        label: "Out of Range",
                        color: Color.vitalyHeart
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func statBadge(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.vitalyTextSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Metadata Card

    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Details", systemImage: "pencil.line")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.vitalyTextPrimary)

            VStack(spacing: 12) {
                fieldRow(label: "Title") {
                    TextField("Checkup title", text: $editableTitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .tint(Color.vitalyPrimary)
                }

                Divider().overlay(Color.white.opacity(0.05))

                fieldRow(label: "Provider") {
                    TextField("Doctor or lab name", text: $editableProvider)
                        .font(.subheadline)
                        .foregroundStyle(Color.vitalyTextPrimary)
                        .tint(Color.vitalyPrimary)
                }

                Divider().overlay(Color.white.opacity(0.05))

                fieldRow(label: "Date") {
                    DatePicker(
                        "",
                        selection: $editableDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .tint(Color.vitalyPrimary)
                    .colorScheme(.dark)
                }
            }
        }
        .padding(16)
        .background(Color.vitalyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.vitalyTextSecondary)
                .frame(width: 70, alignment: .leading)

            content()
        }
    }

    // MARK: - AI Summary Card

    private func aiSummaryCard(summary: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI Summary", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.vitalyRecovery)

            Text(summary)
                .font(.subheadline)
                .foregroundStyle(Color.vitalyTextSecondary)
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.vitalyCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.vitalyRecovery.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Category Card

    private func categoryCard(category: LabCategory, values: [LabValue]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category header
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.subheadline)
                    .foregroundStyle(category.color)

                Text(category.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Spacer()

                let outOfRange = values.filter(\.isOutOfRange).count
                if outOfRange > 0 {
                    Text("\(outOfRange) flagged")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.vitalyHeart)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.vitalyHeart.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            // Lab values
            ForEach(values) { labValue in
                labValueRow(labValue)

                if labValue.id != values.last?.id {
                    Divider().overlay(Color.white.opacity(0.03))
                }
            }
        }
        .padding(16)
        .background(Color.vitalyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private func labValueRow(_ labValue: LabValue) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(labValue.name)
                    .font(.subheadline)
                    .foregroundStyle(Color.vitalyTextPrimary)

                Spacer()

                Text(labValue.formattedValue)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(labValue.isOutOfRange ? Color.vitalyHeart : Color.vitalyTextPrimary)
            }

            HStack {
                if let rangeText = labValue.referenceRangeText {
                    Text("Ref: \(rangeText)")
                        .font(.caption2)
                        .foregroundStyle(Color.vitalyTextSecondary.opacity(0.7))
                }

                Spacer()

                Text(labValue.statusText)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(statusColor(for: labValue))
            }
        }
        .padding(.vertical, 4)
    }

    private func statusColor(for labValue: LabValue) -> Color {
        switch labValue.statusText {
        case "High", "Low":
            return Color.vitalyHeart
        default:
            return Color.vitalyExcellent
        }
    }

    // MARK: - Actions

    private func handlePhotoSelection(item: PhotosPickerItem) {
        isProcessing = true
        processingMessage = "Loading image..."

        Task {
            do {
                guard let picked = try await item.loadTransferable(type: PickableImage.self),
                      let uiImage = UIImage(data: picked.data),
                      let jpegData = uiImage.jpegData(compressionQuality: 0.8) else {
                    throw HealthCheckupError.parseFailed
                }

                processingMessage = "Analyzing lab results with AI..."

                let checkup = try await GeminiService.shared.parseHealthDocument(
                    data: jpegData,
                    mimeType: "image/jpeg"
                )

                applyParsedResult(checkup)
            } catch {
                errorMessage = "Failed to process image: \(error.localizedDescription)"
                isProcessing = false
            }

            selectedPhotoItem = nil
        }
    }

    private func handleCameraImage(_ image: UIImage) {
        isProcessing = true
        processingMessage = "Processing photo..."

        Task {
            do {
                guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
                    throw HealthCheckupError.parseFailed
                }

                processingMessage = "Analyzing lab results with AI..."

                let checkup = try await GeminiService.shared.parseHealthDocument(
                    data: jpegData,
                    mimeType: "image/jpeg"
                )

                applyParsedResult(checkup)
            } catch {
                errorMessage = "Failed to process image: \(error.localizedDescription)"
                isProcessing = false
            }
        }
    }

    private func handleDocumentSelection(url: URL) {
        isProcessing = true
        processingMessage = "Loading document..."

        Task {
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    throw HealthCheckupError.parseFailed
                }
                defer { url.stopAccessingSecurityScopedResource() }

                let data = try Data(contentsOf: url)
                let ext = url.pathExtension.lowercased()
                let mimeType: String
                switch ext {
                case "pdf":
                    mimeType = "application/pdf"
                case "png":
                    mimeType = "image/png"
                case "heic", "heif":
                    mimeType = "image/heic"
                default:
                    mimeType = "image/jpeg"
                }

                processingMessage = "Analyzing lab results with AI..."

                let checkup = try await GeminiService.shared.parseHealthDocument(
                    data: data,
                    mimeType: mimeType
                )

                applyParsedResult(checkup)
            } catch {
                errorMessage = "Failed to process document: \(error.localizedDescription)"
                isProcessing = false
            }
        }
    }

    private func applyParsedResult(_ checkup: HealthCheckup) {
        parsedCheckup = checkup
        editableTitle = checkup.title.isEmpty ? "Health Checkup" : checkup.title
        editableDate = checkup.date
        editableProvider = checkup.provider ?? ""
        isProcessing = false
    }

    private func saveCheckup() {
        guard var checkup = parsedCheckup else { return }

        isSaving = true
        checkup.title = editableTitle
        checkup.date = editableDate
        checkup.provider = editableProvider.isEmpty ? nil : editableProvider
        checkup.updatedAt = Date()

        Task {
            do {
                try await healthCheckupService.saveCheckup(checkup)
                dismiss()
            } catch {
                errorMessage = "Failed to save: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HealthCheckupUploadView(healthCheckupService: HealthCheckupService())
        .preferredColorScheme(.dark)
}
