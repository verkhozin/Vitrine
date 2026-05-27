import Foundation
import SwiftData

@Model
final class CItemPhoto {
    #Unique<CItemPhoto>([\.photoID])

    var photoID: UUID
    var originalFileName: String
    var processedFileName: String?
    var createdAt: Date

    var item: CItem?

    init(
        originalFileName: String,
        processedFileName: String? = nil,
        item: CItem? = nil
    ) {
        self.photoID = UUID()
        self.originalFileName = originalFileName
        self.processedFileName = processedFileName
        self.item = item
        self.createdAt = .now
    }
}

extension CItemPhoto {
    /// Whether AI background removal has been applied
    var hasProcessedVersion: Bool { processedFileName != nil }

    /// The best available file name (processed if exists, otherwise original)
    var displayFileName: String { processedFileName ?? originalFileName }
}
