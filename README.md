<p align="center">
  <img src="docs/logo.png" alt="Vitrine" width="128" />
</p>

<h1 align="center">Vitrine</h1>

<p align="center">A glass display cabinet for your real-world collections — rebuilt around shelves, light, and the satisfaction of arranging things.</p>

<p align="center">
  <img src="docs/demo.gif" alt="Vitrine in action" width="600" />
</p>

Open the app and your collections sit on glass shelves, each item a card resting on a Liquid Glass bar held by two brushed-metal clips. Scroll and the clips catch the light. Pick up a card and drag it to another shelf — the row reflows with a spring and a haptic taps the moment it crosses over. Add an item, snap a photo, and watch a neon sweep trace its silhouette as on-device AI lifts it clean off its background.

## Details that make it feel alive

- **Light-catching shelf clips** — each shelf rests on a glass bar pinned by two brushed-metal clips; as the shelf scrolls, a radial highlight orbits across each clip and the brushed gradient rotates, so the metal catches the light in real time — driven by the actual scroll position, not a timer
- **Glow sweep on the cut-out** — flip *Remove Background* and the lifted subject lights up with a layered blue glow while a soft sweep traces its edge top-to-bottom once, like a scanner pass (1.2s ease)
- **Drag between shelves** — grab any card and drop it on another shelf; items reflow with a spring, the card in hand fades to 30%, and a light haptic fires the instant it lands on a new shelf
- **Liquid Glass throughout** — `glassEffect()` backs the shelf bars (tinted with each collection's color), list rows, detail metadata, and settings cards for a native iOS 26 look
- **Pinch-crop locked to the card** — the crop editor zooms 1×–5× and drags to reposition inside a frame locked to the card's 110:160 aspect, with a dimmed reverse-mask cutout framing the keeper
- **Color-themed detail page** — each item's detail view tints its background gradient and the hero image's shadow with the parent collection's color
- **Procedural covers on first launch** — five collections arrive pre-seeded with generated cover art (a per-item gradient palette, an SF Symbol watermark, the title) so the shelves look full before you've added a thing
- **Editorial header** — "My COLLECTION" set in 38pt black serif with letter-spacing over a quiet secondary line

## What's inside

About 2,500 lines of Swift across `App / Models / Views / Services / Extensions`. Three SwiftData `@Model` types — `CCollection`, `CItem`, `CItemPhoto` — with cascade-delete relationships, surfaced through `@Query`. Photos live as files in the app's Documents directory: originals as JPEG, background-removed cut-outs as PNG to keep their transparency, each indexed by filename on the model and held in an `NSCache` for instant reloads.

Background removal runs `VNGenerateForegroundInstanceMaskRequest` on-device and blends the mask back over the source with `CIBlendWithMask` — no network, no account. Drag-and-drop is plain `NSItemProvider` + `DropDelegate` carrying the item's `persistentModelID` as its transfer token; landing on a card rewrites `sortOrder` on both the source and target shelves. The brushed-metal clips read their own `midY` through `onGeometryChange` to drive the highlight, so the shelf reacts to scrolling with no observers and no state plumbing. No third-party dependencies.

## Requirements

- iOS 26+ (the `glassEffect()` Liquid Glass material is a 26-only API)
- Xcode 26+
- A physical device recommended — the Vision foreground-mask API doesn't run in the Simulator; without it the app still works and simply keeps the original photo

## Build & run

```bash
open Collectioner.xcodeproj    # then ⌘R in Xcode
```

No package manager, no code generation — open and build. On first launch the database seeds five collections (Figurines, Books, Vinyl, Retro Games, Art Prints) with procedurally generated covers, so the shelves are populated immediately.

## Status

A visual exploration, not a shipped product. The first-run data is seeded by `MockDataService` and there's still a hidden **Debug** tab from development. Custom metadata fields are read-only in the UI (they're defined in seed data only), and items can't yet be renamed after they're created — an item editor, editable metadata fields, and iCloud sync are the obvious next steps.

## License

MIT — see [LICENSE](LICENSE).
