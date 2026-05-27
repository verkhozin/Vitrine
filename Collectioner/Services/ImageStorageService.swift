import UIKit

/// Handles saving and loading item photos to the app's Documents directory.
/// Files are organized as: Documents/ItemPhotos/{uuid}.{ext}
final class ImageStorageService: Sendable {

    static let shared = ImageStorageService()

    private let directoryName = "ItemPhotos"
    private let jpegQuality: CGFloat = 0.85
    private nonisolated(unsafe) let cache = NSCache<NSString, UIImage>()

    private var storageURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(directoryName, isDirectory: true)
    }

    private init() {
        ensureDirectoryExists()
    }

    // MARK: - Save

    /// Saves a UIImage as JPEG, returns the filename (not full path).
    func saveImage(_ image: UIImage) -> String? {
        let fixed = image.normalizedOrientation()
        guard let data = fixed.jpegData(compressionQuality: jpegQuality) else { return nil }

        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = storageURL.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL, options: .atomic)
            return fileName
        } catch {
            print("[ImageStorage] Save failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Saves a UIImage as PNG (preserves transparency for background-removed images).
    func saveImageAsPNG(_ image: UIImage) -> String? {
        let fixed = image.normalizedOrientation()
        guard let data = fixed.pngData() else { return nil }

        let fileName = "\(UUID().uuidString).png"
        let fileURL = storageURL.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL, options: .atomic)
            return fileName
        } catch {
            print("[ImageStorage] Save PNG failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Load

    func loadImage(named fileName: String) -> UIImage? {
        let key = fileName as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let fileURL = storageURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let image = UIImage(contentsOfFile: fileURL.path) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    func imageURL(for fileName: String) -> URL {
        storageURL.appendingPathComponent(fileName)
    }

    // MARK: - Delete

    func deleteImage(named fileName: String) {
        cache.removeObject(forKey: fileName as NSString)
        let fileURL = storageURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Deletes both original and processed files for a photo record.
    func deletePhotoPair(original: String, processed: String?) {
        deleteImage(named: original)
        if let processed { deleteImage(named: processed) }
    }

    // MARK: - Storage Info

    var totalStorageBytes: Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: storageURL, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }

    var formattedStorageSize: String {
        ByteCountFormatter.string(fromByteCount: totalStorageBytes, countStyle: .file)
    }

    // MARK: - Private

    private func ensureDirectoryExists() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: storageURL.path) {
            try? fm.createDirectory(at: storageURL, withIntermediateDirectories: true)
        }
    }
}
