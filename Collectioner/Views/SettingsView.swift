import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [CItem]
    @Query private var allCollections: [CCollection]
    @Query private var allPhotos: [CItemPhoto]

    @State private var showResetConfirm = false

    private let imageStorage = ImageStorageService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    settingsSection("Library Stats") {
                        SettingsInfoRow(icon: "square.grid.2x2", title: "Collections", value: "\(allCollections.count)")
                        SettingsInfoRow(icon: "cube.fill", title: "Items", value: "\(allItems.count)")
                        SettingsInfoRow(icon: "photo.fill", title: "Photos", value: "\(allPhotos.count)")
                        SettingsInfoRow(icon: "internaldrive", title: "Storage", value: imageStorage.formattedStorageSize)
                    }

                    settingsSection("About") {
                        SettingsInfoRow(icon: "info.circle", title: "Version", value: "1.0.0")
                        SettingsInfoRow(icon: "swift", title: "Built with", value: "SwiftUI")
                        SettingsInfoRow(icon: "iphone", title: "Platform", value: "iOS 26")
                    }

                    settingsSection("Debug") {
                        Button {
                            showResetConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .frame(width: 28)
                                Text("Reset & Reseed Mock Data")
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .tint(.red)
                    }
                }
                .padding()
            }
            .background {
                LinearGradient(
                    colors: [.gray.opacity(0.12), .blue.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            .navigationTitle("Settings")
            .alert("Reset All Data?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { resetData() }
            } message: {
                Text("All collections and items will be deleted. Fresh mock data will appear on next launch.")
            }
        }
    }

    private func resetData() {
        for item in allItems {
            for photo in item.photos {
                imageStorage.deletePhotoPair(original: photo.originalFileName, processed: photo.processedFileName)
            }
        }
        for collection in allCollections {
            modelContext.delete(collection)
        }
        MockDataService.resetSeedFlag()
        MockDataService.seedIfNeeded(context: modelContext)
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .glassEffect(.clear, in: .rect(cornerRadius: 20))
        }
    }
}

private struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.tint)
                .frame(width: 28)

            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [CCollection.self, CItem.self, CItemPhoto.self], inMemory: true)
}
