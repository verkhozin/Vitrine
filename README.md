<p align="center">
  <img src="docs/logo.png" alt="Vitrine" width="128" />
</p>

<h1 align="center">Vitrine</h1>

<p align="center">A glass display cabinet for your real-world collections — right on your phone.</p>

<p align="center">
  <img src="docs/demo.gif" alt="Vitrine demo" width="600" />
</p>

Figurines, vinyl, books, retro games, art prints — whatever you collect, Vitrine gives each item a card on a visual shelf. Snap a photo, let on-device AI cut the background, drag items between shelves, and browse everything in one place.

## How it works

Create a collection (pick a name, icon, and color), tap **+** to add an item, snap or choose a photo — the app removes the background on-device using Apple Vision — and your item appears on a horizontal shelf. Drag cards between shelves to reorganize. Tap a card to see full details, metadata, and a photo gallery.

## Use cases

- **Action figures** — photograph each figure, remove the background for a clean card, track brand / scale / condition.
- **Vinyl & books** — catalogue your library with cover photos, author, year, and format metadata.
- **Retro games** — log platform, year, completeness (CIB / loose / sealed).
- **Art prints** — keep a visual inventory with artist, year, and print size.
- **Anything else** — custom key-value metadata fields adapt to whatever you collect.

## Features

- **Shelf UI** — each collection is a horizontal scrollable shelf with item cards sitting on a glass bar with metallic clips.
- **Drag & drop** — reorder items within a shelf or move them between shelves with native drag gestures and haptic feedback.
- **AI background removal** — `VNGenerateForegroundInstanceMaskRequest` removes backgrounds on-device, no network needed. Toggle it on or off per photo.
- **Photo crop editor** — pinch-to-zoom, drag-to-reposition crop locked to the card's aspect ratio.
- **Camera & gallery** — add photos from the camera or photo library.
- **Custom metadata** — flexible key-value fields (Brand, Year, Condition, Format, etc.) per item.
- **Favorites** — heart any item; a dedicated tab shows all favorites across collections.
- **Glass effects** — `glassEffect()` on shelf bars, item rows, and detail cards for a native iOS 26 look.
- **Mock data** — ships with five pre-seeded collections (Figurines, Books, Vinyl, Retro Games, Art Prints) with procedurally generated cover art so the app looks alive on first launch.
- **Local storage** — SwiftData for models, JPEG/PNG files in Documents for photos. No server, no account.

## Architecture

~1,500 lines of Swift across `App / Models / Views / Services / Extensions`.

| Layer | What it does |
|-------|-------------|
| **Models** | `CCollection`, `CItem`, `CItemPhoto` — SwiftData `@Model` classes with cascade delete rules |
| **Views** | `CollectionListView` (shelves + drag-drop), `ItemListView` (searchable list), `ItemDetailView` (hero image + metadata), `AddItemSheet` (photo + crop + bg removal), `FavoritesView`, `SettingsView` |
| **Services** | `BackgroundRemovalService` (Vision framework), `ImageStorageService` (Documents dir + NSCache), `MockDataService` (seed data + procedural covers) |
| **Components** | `ShelfBarView` (glass bar + metallic clips with scroll-reactive highlights), `ImageCropView` (interactive crop editor) |

Data flows through SwiftData `@Query` and `@Relationship`. No third-party dependencies.

## Requirements

- iOS 26+
- Xcode 26+
- Physical device recommended (background removal uses Vision APIs unavailable in Simulator)

## Build & run

```bash
open Collectioner.xcodeproj    # then Cmd+R in Xcode
```

No package manager setup, no code generation — open and build.

## License

MIT
