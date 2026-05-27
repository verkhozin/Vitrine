import SwiftUI
import SwiftData
import PhotosUI

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: CItem

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isProcessingPhoto = false
    @State private var showingCamera = false

    private let imageStorage = ImageStorageService.shared
    private let bgRemoval = BackgroundRemovalService.shared

    private var collectionColor: Color {
        Color(hex: item.collection?.colorHex ?? "007AFF") ?? .blue
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroImage
                photoGallery
                infoSection
                customFieldsSection
                actionsSection
            }
            .padding()
        }
        .background {
            LinearGradient(
                colors: [collectionColor.opacity(0.12), .purple.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    item.isFavorite.toggle()
                    item.touch()
                } label: {
                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(item.isFavorite ? .red : .secondary)
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            if let newValue {
                Task { await handlePickedPhoto(newValue) }
            }
        }
    }

    // MARK: - Hero Image

    private var heroImage: some View {
        Group {
            if let photo = item.coverPhoto,
               let uiImage = imageStorage.loadImage(named: photo.displayFileName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: collectionColor.opacity(0.25), radius: 16, y: 8)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(collectionColor.opacity(0.12))
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 10) {
                            Image(systemName: item.collection?.icon ?? "cube.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(collectionColor.opacity(0.5))
                            Text(item.name)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
            }
        }
    }

    // MARK: - Photos

    private var photoGallery: some View {
        VStack(spacing: 12) {
            if item.photos.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(item.photos.sorted(by: { $0.createdAt < $1.createdAt })) { photo in
                            photoCard(photo)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Gallery", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)

                Button {
                    showingCamera = true
                } label: {
                    Label("Camera", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
            }

            if isProcessingPhoto {
                ProgressView("Removing background...")
                    .padding(12)
                    .glassEffect()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func photoCard(_ photo: CItemPhoto) -> some View {
        Group {
            if let image = imageStorage.loadImage(named: photo.displayFileName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 8) {
                LabeledContent("Name") {
                    Text(item.name)
                }

                if !item.notes.isEmpty {
                    LabeledContent("Notes") {
                        Text(item.notes)
                            .multilineTextAlignment(.trailing)
                    }
                }

                LabeledContent("Added") {
                    Text(item.createdAt, style: .date)
                }

                if let collectionName = item.collection?.name {
                    LabeledContent("Collection") {
                        Text(collectionName)
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Custom Fields

    private var customFieldsSection: some View {
        Group {
            if !item.customFields.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Metadata")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)

                    VStack(spacing: 0) {
                        ForEach(item.customFields.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            LabeledContent(key) {
                                Text(value)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                    }
                    .glassEffect()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(role: .destructive) {
                deleteItem()
            } label: {
                Label("Delete Item", systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }

    // MARK: - Logic

    private func handlePickedPhoto(_ pickerItem: PhotosPickerItem) async {
        guard let data = try? await pickerItem.loadTransferable(type: Data.self),
              let originalImage = UIImage(data: data) else { return }

        isProcessingPhoto = true
        defer { isProcessingPhoto = false }

        guard let originalFileName = imageStorage.saveImage(originalImage) else { return }

        let processedImage = await bgRemoval.removeBackground(from: originalImage)
        let processedFileName = imageStorage.saveImageAsPNG(processedImage)

        let photo = CItemPhoto(
            originalFileName: originalFileName,
            processedFileName: processedFileName,
            item: item
        )
        modelContext.insert(photo)
        item.touch()

        selectedPhotoItem = nil
    }

    private func deleteItem() {
        for photo in item.photos {
            imageStorage.deletePhotoPair(original: photo.originalFileName, processed: photo.processedFileName)
        }
        modelContext.delete(item)
    }
}
