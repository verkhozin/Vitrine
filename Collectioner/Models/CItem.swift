import Foundation
import SwiftData

@Model
final class CItem {
    var name: String
    var notes: String
    var isFavorite: Bool
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    var collection: CCollection?

    @Relationship(deleteRule: .cascade, inverse: \CItemPhoto.item)
    var photos: [CItemPhoto] = []

    /// Flexible key-value metadata (e.g. "Year": "1985", "Condition": "Mint")
    var customFields: [String: String] = [:]

    init(
        name: String,
        notes: String = "",
        isFavorite: Bool = false,
        sortOrder: Int = 0,
        collection: CCollection? = nil
    ) {
        self.name = name
        self.notes = notes
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder
        self.collection = collection
        self.createdAt = .now
        self.updatedAt = .now
    }
}

extension CItem {
    var coverPhoto: CItemPhoto? {
        photos.sorted { $0.createdAt < $1.createdAt }.first
    }

    func touch() {
        updatedAt = .now
    }

    @MainActor static let previewSamples: [CItem] = {
        let item1 = CItem(name: "Darth Vader 1:6 Scale", notes: "Hot Toys, Empire Strikes Back edition")
        item1.customFields = ["Brand": "Hot Toys", "Scale": "1:6", "Condition": "Mint"]

        let item2 = CItem(name: "Neuromancer", notes: "First edition hardcover")
        item2.customFields = ["Author": "William Gibson", "Year": "1984", "Condition": "Good"]

        let item3 = CItem(name: "Abbey Road", notes: "Original UK pressing")
        item3.customFields = ["Artist": "The Beatles", "Year": "1969", "Format": "LP"]
        item3.isFavorite = true

        return [item1, item2, item3]
    }()
}
