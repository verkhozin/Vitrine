import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(
        filter: #Predicate<CItem> { $0.isFavorite },
        sort: \CItem.updatedAt,
        order: .reverse
    )
    private var favorites: [CItem]

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    ContentUnavailableView(
                        "No Favorites Yet",
                        systemImage: "heart.slash",
                        description: Text("Items you mark as favorite will appear here.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(favorites) { item in
                                NavigationLink(value: item) {
                                    FavoriteRowView(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
            .background {
                LinearGradient(
                    colors: [.pink.opacity(0.15), .orange.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            .navigationTitle("Favorites")
            .navigationDestination(for: CItem.self) { item in
                ItemDetailView(item: item)
            }
        }
    }
}

private struct FavoriteRowView: View {
    let item: CItem
    private let imageStorage = ImageStorageService.shared

    var body: some View {
        HStack(spacing: 16) {
            if let photo = item.coverPhoto,
               let image = imageStorage.loadImage(named: photo.displayFileName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red.opacity(0.5))
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)

                if let collectionName = item.collection?.name {
                    Text(collectionName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
                .font(.subheadline)
        }
        .padding(14)
        .glassEffect()
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    FavoritesView()
        .modelContainer(for: [CCollection.self, CItem.self, CItemPhoto.self], inMemory: true)
}
