import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Collections", systemImage: "square.grid.2x2.fill", value: 0) {
                CollectionListView()
            }

            Tab("Favorites", systemImage: "heart.fill", value: 1) {
                FavoritesView()
            }

            Tab("Settings", systemImage: "gearshape.fill", value: 2) {
                SettingsView()
            }

            Tab("Debug", systemImage: "wrench.fill", value: 3) {
                ShelfDebugView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [CCollection.self, CItem.self, CItemPhoto.self], inMemory: true)
}
