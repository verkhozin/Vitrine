import SwiftUI
import SwiftData

@main
struct CollectionerApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            CCollection.self,
            CItem.self,
            CItemPhoto.self,
        ])
        let config = ModelConfiguration(
            "Collectioner",
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // One-time re-seed with sortOrder support
        let reseedKey = "com.collectioner.mockDataV4"
        if !UserDefaults.standard.bool(forKey: reseedKey) {
            MockDataService.resetSeedFlag()
            // Clear old data
            let ctx = modelContainer.mainContext
            try? ctx.delete(model: CItemPhoto.self)
            try? ctx.delete(model: CItem.self)
            try? ctx.delete(model: CCollection.self)
            UserDefaults.standard.set(true, forKey: reseedKey)
        }
        MockDataService.seedIfNeeded(context: modelContainer.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
