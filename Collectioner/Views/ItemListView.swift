import SwiftUI
import SwiftData

struct ItemListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var collection: CCollection

    @State private var showingAddItem = false
    @State private var searchText = ""

    private let imageStorage = ImageStorageService.shared

    private var filteredItems: [CItem] {
        let sorted = collection.items.sorted { $0.updatedAt > $1.updatedAt }
        if searchText.isEmpty { return sorted }
        return sorted.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || $0.notes.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            if collection.items.isEmpty {
                ContentUnavailableView(
                    "No Items",
                    systemImage: "tray",
                    description: Text("Tap + to add your first item.")
                )
                .padding(.top, 80)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredItems) { item in
                        NavigationLink(value: item) {
                            ItemRowView(item: item)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteItem(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .background {
            LinearGradient(
                colors: [
                    (Color(hex: collection.colorHex) ?? .blue).opacity(0.15),
                    .purple.opacity(0.08),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .navigationTitle(collection.name)
        .navigationDestination(for: CItem.self) { item in
            ItemDetailView(item: item)
        }
        .searchable(text: $searchText, prompt: "Search items...")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemSheet(collection: collection)
        }
    }

    private func deleteItem(_ item: CItem) {
        for photo in item.photos {
            imageStorage.deletePhotoPair(original: photo.originalFileName, processed: photo.processedFileName)
        }
        modelContext.delete(item)
    }
}

// MARK: - Item Row

private struct ItemRowView: View {
    let item: CItem

    @State private var loadedImage: UIImage?

    var body: some View {
        HStack(spacing: 16) {
            if let loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.tertiary)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)

                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if item.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
                    .font(.subheadline)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .glassEffect()
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .task(id: item.coverPhoto?.displayFileName) {
            guard let fileName = item.coverPhoto?.displayFileName else {
                loadedImage = nil
                return
            }
            loadedImage = await Task.detached {
                ImageStorageService.shared.loadImage(named: fileName)
            }.value
        }
    }
}

