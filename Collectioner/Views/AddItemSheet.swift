import SwiftUI
import SwiftData
import PhotosUI

struct AddItemSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let collection: CCollection

    @State private var name = ""
    @State private var notes = ""

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var croppedImage: UIImage?
    @State private var removeBackground = false
    @State private var isProcessing = false
    @State private var showCamera = false
    @State private var showCropEditor = false
    @State private var outlineSweep: CGFloat = 0
    @State private var outlineSweepID = UUID()

    private let bgRemoval = BackgroundRemovalService.shared
    private let imageStorage = ImageStorageService.shared

    private let cardAspect: CGFloat = 110.0 / 160.0

    /// The image that will be shown as the card cover
    private var displayImage: UIImage? {
        if let croppedImage { return croppedImage }
        if removeBackground, let processedImage { return processedImage }
        return pickedImage
    }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                detailsSection
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                if let newValue {
                    Task { await loadPhoto(from: newValue) }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { image in
                    if let image {
                        Task { await processPickedImage(image) }
                    }
                }
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showCropEditor) {
                if let source = displayImage {
                    ImageCropView(
                        image: source,
                        targetAspect: cardAspect,
                        onDone: { cropped in
                            croppedImage = cropped
                            showCropEditor = false
                        },
                        onCancel: {
                            showCropEditor = false
                        }
                    )
                }
            }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        Section {
            if isProcessing {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Removing background...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            } else if pickedImage != nil {
                photoPreview
            } else {
                photoPickerButtons
            }
        } header: {
            Text("Photo")
        } footer: {
            if pickedImage == nil && !isProcessing {
                Text("You can choose to remove the background using on-device AI.")
            }
        }
    }

    private var photoPreview: some View {
        VStack(spacing: 14) {
            if let display = displayImage {
                let showGlow = removeBackground && processedImage != nil

                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(showGlow ? Color(white: 0.08) : Color(white: 0.95))

                    Image(uiImage: display)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                        .shadow(color: showGlow ? .white.opacity(0.85) : .clear, radius: 1.5)
                        .shadow(color: showGlow ? Color(red: 0.45, green: 0.75, blue: 1.0).opacity(0.55) : .clear, radius: 4)
                        .shadow(color: showGlow ? Color(red: 0.45, green: 0.75, blue: 1.0).opacity(0.2) : .clear, radius: 10)
                        .overlay {
                            if showGlow {
                                Image(uiImage: display)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding(8)
                                    .colorMultiply(Color(red: 0.45, green: 0.75, blue: 1.0))
                                    .blur(radius: 3)
                                    .mask {
                                        LinearGradient(
                                            stops: [
                                                .init(color: .white, location: max(0, outlineSweep - 0.08)),
                                                .init(color: .clear, location: outlineSweep),
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    }
                                    .opacity(outlineSweep >= 1.15 ? 0 : 1)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                .frame(maxHeight: 180)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .frame(maxWidth: .infinity)
                .animation(.easeInOut(duration: 0.3), value: showGlow)
                .onChange(of: showGlow) { _, isGlowing in
                    if isGlowing {
                        outlineSweep = -0.15
                        outlineSweepID = UUID()
                        withAnimation(.easeInOut(duration: 1.2)) {
                            outlineSweep = 1.15
                        }
                    } else {
                        outlineSweep = 0
                    }
                }
            }

            if processedImage != nil {
                Toggle(isOn: $removeBackground) {
                    Label("Remove Background", systemImage: "person.and.background.dotted")
                }
                .onChange(of: removeBackground) { _, _ in
                    croppedImage = nil
                }
            }

            HStack(spacing: 12) {
                Button {
                    showCropEditor = true
                } label: {
                    Label("Adjust", systemImage: "crop")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    clearPhoto()
                } label: {
                    Label("Remove", systemImage: "trash")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }

    private var photoPickerButtons: some View {
        HStack(spacing: 16) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title2)
                    Text("Gallery")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .buttonStyle(.bordered)

            Button {
                showCamera = true
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                    Text("Camera")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        Section("Details") {
            TextField("Item name", text: $name)
            TextField("Notes (optional)", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Logic

    private func loadPhoto(from pickerItem: PhotosPickerItem) async {
        guard let data = try? await pickerItem.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await processPickedImage(image)
    }

    private func processPickedImage(_ image: UIImage) async {
        let normalized = image.normalizedOrientation()
        pickedImage = normalized
        isProcessing = true

        let result = await bgRemoval.removeBackground(from: normalized)
        processedImage = result
        croppedImage = nil
        removeBackground = false

        isProcessing = false
        selectedPhotoItem = nil
    }

    private func clearPhoto() {
        pickedImage = nil
        processedImage = nil
        croppedImage = nil
        selectedPhotoItem = nil
        removeBackground = false
    }

    private func save() {
        let nextOrder = (collection.items.map(\.sortOrder).max() ?? -1) + 1
        let item = CItem(
            name: name.trimmingCharacters(in: .whitespaces),
            notes: notes.trimmingCharacters(in: .whitespaces),
            sortOrder: nextOrder,
            collection: collection
        )
        modelContext.insert(item)
        try? modelContext.save()

        let original = pickedImage
        let finalImage: UIImage? = if let croppedImage {
            croppedImage
        } else if removeBackground, let processedImage {
            processedImage
        } else {
            nil
        }
        dismiss()

        guard let original else { return }

        Task {
            let (origFile, processedFile) = await Task.detached {
                let storage = ImageStorageService.shared
                let originalFileName = storage.saveImage(original)
                let processedFileName: String? = if let img = finalImage {
                    storage.saveImageAsPNG(img)
                } else {
                    nil
                }
                return (originalFileName, processedFileName)
            }.value

            guard let origFile else { return }

            let photo = CItemPhoto(
                originalFileName: origFile,
                processedFileName: processedFile,
                item: item
            )
            modelContext.insert(photo)
            try? modelContext.save()
        }
    }
}

// MARK: - Camera UIKit Bridge

private struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage?) -> Void
        init(onCapture: @escaping (UIImage?) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true) { [weak self] in
                self?.onCapture(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) { [weak self] in
                self?.onCapture(nil)
            }
        }
    }
}
