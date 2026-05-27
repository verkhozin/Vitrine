import Foundation
import SwiftData

@Model
final class CCollection {
    var name: String
    var icon: String
    var colorHex: String
    var createdAt: Date
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \CItem.collection)
    var items: [CItem] = []

    init(
        name: String,
        icon: String = "folder.fill",
        colorHex: String = "007AFF",
        sortOrder: Int = 0
    ) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = .now
        self.sortOrder = sortOrder
    }
}

extension CCollection {
    var itemCount: Int { items.count }

    var favoriteCount: Int { items.filter(\.isFavorite).count }

    @MainActor static let previewSamples: [CCollection] = {
        let figurines = CCollection(name: "Figurines", icon: "figure.stand", colorHex: "FF6B35")
        let books = CCollection(name: "Books", icon: "book.fill", colorHex: "5856D6")
        let vinyl = CCollection(name: "Vinyl Records", icon: "opticaldisc.fill", colorHex: "34C759")
        return [figurines, books, vinyl]
    }()
}
