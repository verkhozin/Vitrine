import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CollectionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CCollection.sortOrder) private var collections: [CCollection]

    @State private var navigationPath = NavigationPath()
    @State private var showingAddCollection = false
    @State private var selectedCollectionForAdd: CCollection?

    @State private var draggedItem: CItem?
    @State private var dragSourceCollection: CCollection?
    @State private var hasChangedLocation = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.top, 20)
                        .padding(.bottom, 32)

                    if collections.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 28) {
                            ForEach(collections) { collection in
                                ShelfSectionView(
                                    collection: collection,
                                    draggedItem: $draggedItem,
                                    dragSourceCollection: $dragSourceCollection,
                                    hasChangedLocation: $hasChangedLocation,
                                    onSelectItem: { item in
                                        guard draggedItem == nil else { return }
                                        navigationPath.append(item)
                                    },
                                    onAddItem: {
                                        selectedCollectionForAdd = collection
                                    }
                                )
                            }
                        }
                    }

                    addButton
                        .padding(.top, 40)
                        .padding(.bottom, 32)
                }
            }
            .onDrop(of: [UTType.text], delegate: BackgroundDropDelegate(
                draggedItem: $draggedItem,
                dragSourceCollection: $dragSourceCollection,
                hasChangedLocation: $hasChangedLocation
            ))
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: CCollection.self) { collection in
                ItemListView(collection: collection)
            }
            .navigationDestination(for: CItem.self) { item in
                ItemDetailView(item: item)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddCollection = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCollection) {
                AddCollectionSheet()
                    .presentationDetents([.medium])
            }
            .sheet(item: $selectedCollectionForAdd) { collection in
                AddItemSheet(collection: collection)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 2) {
            Text("My")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("COLLECTION")
                .font(.system(size: 38, weight: .black, design: .serif))
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("No collections yet")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Create your first collection to start\nbuilding your digital library.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showingAddCollection = true
        } label: {
            Text("Add Collection")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 36)
                .padding(.vertical, 14)
                .background(.black, in: Capsule())
        }
    }

}

// MARK: - Shelf Section

private struct ShelfSectionView: View {
    @Environment(\.modelContext) private var modelContext
    let collection: CCollection
    @Binding var draggedItem: CItem?
    @Binding var dragSourceCollection: CCollection?
    @Binding var hasChangedLocation: Bool
    let onSelectItem: (CItem) -> Void
    let onAddItem: () -> Void

    private let imageStorage = ImageStorageService.shared
    private let itemHeight: CGFloat = 160
    private let itemWidth: CGFloat = 110
    private let shelfHeight: CGFloat = 44

    private var sortedItems: [CItem] {
        collection.items.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            ZStack(alignment: .bottom) {
                itemsRow
                shelfBar.zIndex(1)
            }
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(collection.name)
                .font(.title3.weight(.semibold))

            Spacer()

            HStack(spacing: 12) {
                Text("\(collection.itemCount) items")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                NavigationLink(value: collection) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Items Row

    private var itemsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(sortedItems) { item in
                    let isBeingDragged = draggedItem?.persistentModelID == item.persistentModelID

                    ShelfItemCard(
                        item: item,
                        width: itemWidth,
                        height: itemHeight
                    )
                    .opacity(isBeingDragged && hasChangedLocation ? 0.3 : 1)
                    .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 10))
                    .contentShape(.interaction, RoundedRectangle(cornerRadius: 10))
                    .simultaneousGesture(TapGesture().onEnded {
                        guard draggedItem == nil else { return }
                        onSelectItem(item)
                    })
                    .onDrag {
                        draggedItem = item
                        dragSourceCollection = collection
                        return NSItemProvider(object: "\(item.persistentModelID)" as NSString)
                    }
                    .onDrop(of: [UTType.text], delegate: ItemReorderDelegate(
                        item: item,
                        collection: collection,
                        draggedItem: $draggedItem,
                        dragSourceCollection: $dragSourceCollection,
                        hasChangedLocation: $hasChangedLocation
                    ))
                    .contextMenu {
                        Button {
                            onSelectItem(item)
                        } label: {
                            Label("Open", systemImage: "arrow.right.circle")
                        }
                        Button(role: .destructive) {
                            deleteItem(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                addItemButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, shelfHeight * 0.55)
        }
    }

    // MARK: - Shelf Bar

    private var shelfBar: some View {
        let color = Color(hex: collection.colorHex) ?? .blue
        return ShelfBarView(color: color, height: shelfHeight + 30)
    }

    // MARK: - Delete

    private func deleteItem(_ item: CItem) {
        for photo in item.photos {
            imageStorage.deletePhotoPair(original: photo.originalFileName, processed: photo.processedFileName)
        }
        modelContext.delete(item)
    }

    // MARK: - Add Item Button

    private var addItemButton: some View {
        Button(action: onAddItem) {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .foregroundStyle(.tertiary)
                .frame(width: itemWidth, height: itemHeight)
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.title2)
                        Text("Add")
                            .font(.caption)
                    }
                    .foregroundStyle(.tertiary)
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Item Reorder Drop Delegate

private struct ItemReorderDelegate: DropDelegate {
    let item: CItem
    let collection: CCollection
    @Binding var draggedItem: CItem?
    @Binding var dragSourceCollection: CCollection?
    @Binding var hasChangedLocation: Bool

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedItem,
              dragged.persistentModelID != item.persistentModelID,
              let sourceCollection = dragSourceCollection else { return }

        hasChangedLocation = true
        let sameShelf = sourceCollection.persistentModelID == collection.persistentModelID

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if sameShelf {
                reorderWithinShelf(dragged: dragged)
            } else {
                moveBetweenShelves(dragged: dragged, from: sourceCollection)
            }
        }

        if !sameShelf {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        hasChangedLocation = false
        draggedItem = nil
        dragSourceCollection = nil
        return true
    }

    private func reorderWithinShelf(dragged: CItem) {
        var items = collection.items.sorted { $0.sortOrder < $1.sortOrder }
        guard let from = items.firstIndex(where: { $0.persistentModelID == dragged.persistentModelID }),
              let to = items.firstIndex(where: { $0.persistentModelID == item.persistentModelID }) else { return }

        items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        for (i, it) in items.enumerated() { it.sortOrder = i }
    }

    private func moveBetweenShelves(dragged: CItem, from sourceCollection: CCollection) {
        dragged.sortOrder = Int.max
        dragged.collection = collection
        dragSourceCollection = collection

        let sourceItems = sourceCollection.items.sorted { $0.sortOrder < $1.sortOrder }
        for (i, it) in sourceItems.enumerated() { it.sortOrder = i }

        var targetItems = collection.items.sorted { $0.sortOrder < $1.sortOrder }
        guard let fromIdx = targetItems.firstIndex(where: { $0.persistentModelID == dragged.persistentModelID }),
              let toIdx = targetItems.firstIndex(where: { $0.persistentModelID == item.persistentModelID }) else { return }

        targetItems.move(fromOffsets: IndexSet(integer: fromIdx), toOffset: toIdx > fromIdx ? toIdx + 1 : toIdx)
        for (i, it) in targetItems.enumerated() { it.sortOrder = i }
    }
}

// MARK: - Background Drop Delegate (catch-all for drops outside shelves)

private struct BackgroundDropDelegate: DropDelegate {
    @Binding var draggedItem: CItem?
    @Binding var dragSourceCollection: CCollection?
    @Binding var hasChangedLocation: Bool

    func performDrop(info: DropInfo) -> Bool {
        hasChangedLocation = false
        draggedItem = nil
        dragSourceCollection = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

// MARK: - Shelf Item Card

private struct ShelfItemCard: View {
    let item: CItem
    let width: CGFloat
    let height: CGFloat

    @State private var loadedImage: UIImage?

    var body: some View {
        Group {
            if let loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                placeholderCard
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.12), radius: 6, x: 2, y: 4)
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

    private var placeholderCard: some View {
        let bgColor = Color(hex: item.collection?.colorHex ?? "CCCCCC") ?? .gray

        return ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(bgColor.opacity(0.15))

            VStack(spacing: 6) {
                Image(systemName: item.collection?.icon ?? "cube.fill")
                    .font(.title2)
                    .foregroundStyle(bgColor.opacity(0.6))

                Text(item.name)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 6)
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Add Collection Sheet

private struct AddCollectionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColorHex = "007AFF"

    private let iconOptions = [
        "folder.fill", "figure.stand", "book.fill", "opticaldisc.fill",
        "gamecontroller.fill", "paintpalette.fill", "camera.fill", "star.fill",
        "gift.fill", "cube.fill", "puzzlepiece.fill", "trophy.fill",
    ]

    private let colorOptions = [
        "007AFF", "FF6B35", "5856D6", "34C759",
        "FF2D55", "FF9500", "AF52DE", "5AC8FA",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Collection name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if selectedColorHex == hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { selectedColorHex = hex }
                        }
                    }
                }
            }
            .navigationTitle("New Collection")
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
        }
    }

    private func save() {
        let collection = CCollection(
            name: name.trimmingCharacters(in: .whitespaces),
            icon: selectedIcon,
            colorHex: selectedColorHex
        )
        modelContext.insert(collection)
        dismiss()
    }
}

#Preview {
    CollectionListView()
        .modelContainer(for: [CCollection.self, CItem.self, CItemPhoto.self], inMemory: true)
}
