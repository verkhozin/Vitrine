import UIKit
import SwiftData

/// Seeds the database with sample data on first launch.
/// Checks a UserDefaults flag to avoid re-seeding.
enum MockDataService {

    private static let seededKey = "com.collectioner.mockDataSeeded"

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }

        let imageStorage = ImageStorageService.shared

        let figurines = makeCollection(
            name: "Figurines", icon: "figure.stand", colorHex: "E04030", sortOrder: 0,
            items: [
                ("Darth Vader 1:6", "Hot Toys, Empire Strikes Back edition", true,
                 ["Brand": "Hot Toys", "Scale": "1:6", "Condition": "Mint"]),
                ("Spider-Man Miles Morales", "Sentinel SV-Action, Into the Spider-Verse", false,
                 ["Brand": "Sentinel", "Scale": "1:10", "Condition": "New"]),
                ("Evangelion Unit-01", "Bandai RG, Neon Genesis", false,
                 ["Brand": "Bandai", "Scale": "RG", "Condition": "Assembled"]),
                ("Berserk Guts", "Prime 1 Studio, Black Swordsman", true,
                 ["Brand": "Prime 1 Studio", "Scale": "1:4", "Condition": "Mint"]),
                ("Totoro", "Benelic, My Neighbor Totoro", false,
                 ["Brand": "Benelic", "Scale": "1:1", "Condition": "Good"]),
                ("Link - Tears of the Kingdom", "First 4 Figures, collector edition", false,
                 ["Brand": "First 4 Figures", "Scale": "1:4", "Condition": "New"]),
            ]
        )

        let books = makeCollection(
            name: "Books", icon: "book.fill", colorHex: "2080E0", sortOrder: 1,
            items: [
                ("Neuromancer", "William Gibson, first edition hardcover", true,
                 ["Author": "William Gibson", "Year": "1984", "Condition": "Good"]),
                ("Dune", "Frank Herbert, 1965 Chilton Books", false,
                 ["Author": "Frank Herbert", "Year": "1965", "Condition": "Fair"]),
                ("House of Leaves", "Mark Z. Danielewski, full-color edition", false,
                 ["Author": "Mark Z. Danielewski", "Year": "2000", "Condition": "Very Good"]),
                ("The Design of Everyday Things", "Don Norman, revised edition", false,
                 ["Author": "Don Norman", "Year": "2013", "Condition": "New"]),
                ("Bauhaus", "Magdalena Droste, Taschen", true,
                 ["Author": "Magdalena Droste", "Year": "2019", "Condition": "Mint"]),
                ("Dieter Rams: Ten Principles", "Cees W. de Jong", false,
                 ["Author": "Cees W. de Jong", "Year": "2017", "Condition": "Good"]),
                ("Snow Crash", "Neal Stephenson, Bantam Books", false,
                 ["Author": "Neal Stephenson", "Year": "1992", "Condition": "Good"]),
                ("Sapiens", "Yuval Noah Harari", false,
                 ["Author": "Yuval Noah Harari", "Year": "2011", "Condition": "Very Good"]),
            ]
        )

        let vinyl = makeCollection(
            name: "Vinyl Records", icon: "opticaldisc.fill", colorHex: "18A050", sortOrder: 2,
            items: [
                ("Abbey Road", "The Beatles, original UK pressing", true,
                 ["Artist": "The Beatles", "Year": "1969", "Format": "LP"]),
                ("Kind of Blue", "Miles Davis, Columbia Records", true,
                 ["Artist": "Miles Davis", "Year": "1959", "Format": "LP"]),
                ("OK Computer", "Radiohead, Parlophone", false,
                 ["Artist": "Radiohead", "Year": "1997", "Format": "LP"]),
                ("Rumours", "Fleetwood Mac, Warner Bros.", false,
                 ["Artist": "Fleetwood Mac", "Year": "1977", "Format": "LP"]),
                ("The Dark Side of the Moon", "Pink Floyd, Harvest Records", false,
                 ["Artist": "Pink Floyd", "Year": "1973", "Format": "LP"]),
            ]
        )

        let games = makeCollection(
            name: "Retro Games", icon: "gamecontroller.fill", colorHex: "E0A020", sortOrder: 3,
            items: [
                ("The Legend of Zelda: OoT", "N64, CIB, 1998", true,
                 ["Platform": "N64", "Year": "1998", "Condition": "Complete"]),
                ("Chrono Trigger", "SNES, cartridge only", false,
                 ["Platform": "SNES", "Year": "1995", "Condition": "Loose"]),
                ("Metal Gear Solid", "PS1, black label", false,
                 ["Platform": "PS1", "Year": "1998", "Condition": "Complete"]),
                ("Final Fantasy VII", "PS1, original 3-disc set", true,
                 ["Platform": "PS1", "Year": "1997", "Condition": "Complete"]),
            ]
        )

        let art = makeCollection(
            name: "Art Prints", icon: "paintpalette.fill", colorHex: "9030C0", sortOrder: 4,
            items: [
                ("Great Wave off Kanagawa", "Hokusai, woodblock reproduction", false,
                 ["Artist": "Katsushika Hokusai", "Year": "1831", "Size": "24x36"]),
                ("Starry Night", "Van Gogh, museum print", true,
                 ["Artist": "Vincent van Gogh", "Year": "1889", "Size": "18x24"]),
                ("Girl with a Pearl Earring", "Vermeer, Rijksmuseum edition", false,
                 ["Artist": "Johannes Vermeer", "Year": "1665", "Size": "16x20"]),
            ]
        )

        let allCollections = [figurines, books, vinyl, games, art]
        for collection in allCollections {
            context.insert(collection)
        }

        for collection in allCollections {
            let baseColor = UIColor(hex: collection.colorHex) ?? .systemBlue
            for (index, item) in collection.items.enumerated() {
                let cover = generateCoverImage(
                    title: item.name,
                    icon: collection.icon,
                    baseColor: baseColor,
                    seed: index
                )
                if let fileName = imageStorage.saveImage(cover) {
                    let photo = CItemPhoto(originalFileName: fileName, item: item)
                    context.insert(photo)
                }
            }
        }

        UserDefaults.standard.set(true, forKey: seededKey)
    }

    static func resetSeedFlag() {
        UserDefaults.standard.removeObject(forKey: seededKey)
    }

    // MARK: - Private

    private static func makeCollection(
        name: String,
        icon: String,
        colorHex: String,
        sortOrder: Int,
        items: [(String, String, Bool, [String: String])]
    ) -> CCollection {
        let collection = CCollection(name: name, icon: icon, colorHex: colorHex, sortOrder: sortOrder)
        for (index, (itemName, notes, isFav, fields)) in items.enumerated() {
            let item = CItem(name: itemName, notes: notes, isFavorite: isFav, sortOrder: index, collection: collection)
            item.customFields = fields
            collection.items.append(item)
        }
        return collection
    }

    // MARK: - Cover Generation

    private static let coverPalettes: [[UIColor]] = [
        [UIColor(red: 0.95, green: 0.85, blue: 0.65, alpha: 1), UIColor(red: 0.85, green: 0.55, blue: 0.30, alpha: 1)],
        [UIColor(red: 0.20, green: 0.20, blue: 0.35, alpha: 1), UIColor(red: 0.45, green: 0.35, blue: 0.65, alpha: 1)],
        [UIColor(red: 0.90, green: 0.30, blue: 0.25, alpha: 1), UIColor(red: 0.70, green: 0.15, blue: 0.20, alpha: 1)],
        [UIColor(red: 0.15, green: 0.50, blue: 0.65, alpha: 1), UIColor(red: 0.10, green: 0.30, blue: 0.50, alpha: 1)],
        [UIColor(red: 0.95, green: 0.90, blue: 0.80, alpha: 1), UIColor(red: 0.80, green: 0.70, blue: 0.55, alpha: 1)],
        [UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1), UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1)],
        [UIColor(red: 0.30, green: 0.60, blue: 0.50, alpha: 1), UIColor(red: 0.15, green: 0.40, blue: 0.35, alpha: 1)],
        [UIColor(red: 0.85, green: 0.75, blue: 0.90, alpha: 1), UIColor(red: 0.55, green: 0.35, blue: 0.70, alpha: 1)],
    ]

    private static func generateCoverImage(
        title: String,
        icon: String,
        baseColor: UIColor,
        seed: Int
    ) -> UIImage {
        let size = CGSize(width: 220, height: 320)
        let renderer = UIGraphicsImageRenderer(size: size)

        let palette = coverPalettes[seed % coverPalettes.count]

        return renderer.image { ctx in
            let context = ctx.cgContext

            // Gradient background
            let colors = palette.map(\.cgColor) as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) {
                context.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width * 0.3, y: size.height),
                    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
                )
            }

            // Decorative geometric shape
            context.saveGState()
            let circleSize: CGFloat = 100
            let circleX = size.width * 0.55
            let circleY = size.height * 0.25
            context.setFillColor(UIColor.white.withAlphaComponent(0.12).cgColor)
            context.fillEllipse(in: CGRect(x: circleX, y: circleY, width: circleSize, height: circleSize))
            context.restoreGState()

            // SF Symbol icon
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 36, weight: .light)
            if let symbolImage = UIImage(systemName: icon, withConfiguration: symbolConfig) {
                let tinted = symbolImage.withTintColor(.white.withAlphaComponent(0.35), renderingMode: .alwaysOriginal)
                let iconRect = CGRect(
                    x: size.width - 56,
                    y: 20,
                    width: 40,
                    height: 40
                )
                tinted.draw(in: iconRect)
            }

            // Title text
            let titleFont = UIFont.systemFont(ofSize: 18, weight: .bold)
            let titleColor = isLightColor(palette[0]) ? UIColor.black.withAlphaComponent(0.85) : UIColor.white.withAlphaComponent(0.95)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: titleColor,
                .paragraphStyle: paragraphStyle,
            ]
            let titleRect = CGRect(x: 18, y: size.height - 110, width: size.width - 36, height: 90)
            (title as NSString).draw(in: titleRect, withAttributes: titleAttrs)

            // Thin line separator above title
            context.setStrokeColor(titleColor.withAlphaComponent(0.2).cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: 18, y: size.height - 118))
            context.addLine(to: CGPoint(x: size.width - 18, y: size.height - 118))
            context.strokePath()
        }
    }

    private static func isLightColor(_ color: UIColor) -> Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: nil)
        return (r * 0.299 + g * 0.587 + b * 0.114) > 0.6
    }
}

// MARK: - UIColor hex helper (internal, only for mock generation)

private extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        guard hexSanitized.count == 6, let rgb = UInt64(hexSanitized, radix: 16) else { return nil }
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}
