import SwiftUI

/// Interactive crop editor: pinch to zoom, drag to reposition within a target frame.
/// Returns the cropped UIImage via `onDone`.
struct ImageCropView: View {
    let image: UIImage
    let targetAspect: CGFloat // width / height, e.g. 110/160 for shelf card
    let onDone: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var viewFrameWidth: CGFloat = 300

    private var imageAspect: CGFloat {
        guard image.size.height > 0 else { return 1 }
        return image.size.width / image.size.height
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let frameWidth = geo.size.width * 0.7
                let frameHeight = frameWidth / targetAspect

                ZStack {
                    Color.black.ignoresSafeArea()

                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: frameWidth * scale, height: frameHeight * scale)
                        .offset(offset)
                        .gesture(dragGesture)
                        .gesture(magnifyGesture)
                        .frame(width: frameWidth, height: frameHeight)
                        .clipped()

                    cropOverlay(frameWidth: frameWidth, frameHeight: frameHeight, in: geo.size)
                }
                .onAppear { viewFrameWidth = frameWidth }
                .onChange(of: geo.size) { _, newSize in
                    viewFrameWidth = newSize.width * 0.7
                }
            }
            .navigationTitle("Adjust Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { cropAndReturn() }
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            }
        }
    }

    // MARK: - Overlay

    private func cropOverlay(frameWidth: CGFloat, frameHeight: CGFloat, in containerSize: CGSize) -> some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.5))
                .reverseMask {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: frameWidth, height: frameHeight)
                }
                .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.white.opacity(0.6), lineWidth: 1)
                .frame(width: frameWidth, height: frameHeight)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = lastScale * value.magnification
                scale = max(1.0, min(newScale, 5.0))
            }
            .onEnded { _ in
                lastScale = scale
            }
    }

    // MARK: - Crop

    private func cropAndReturn() {
        let targetW: CGFloat = 440
        let targetH = targetW / targetAspect
        let targetSize = CGSize(width: targetW, height: targetH)

        let imgSize = image.size
        let scaleToFill = max(targetW / imgSize.width, targetH / imgSize.height) * (1 / scale)

        let drawW = imgSize.width * scaleToFill * scale
        let drawH = imgSize.height * scaleToFill * scale

        let viewFrameH = viewFrameWidth / targetAspect
        let normalizedOffsetX = offset.width / viewFrameWidth * targetW
        let normalizedOffsetY = offset.height / viewFrameH * targetH

        let drawX = (targetW - drawW) / 2 + normalizedOffsetX
        let drawY = (targetH - drawH) / 2 + normalizedOffsetY

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let cropped = renderer.image { _ in
            image.draw(in: CGRect(x: drawX, y: drawY, width: drawW, height: drawH))
        }
        onDone(cropped)
    }
}

// MARK: - Reverse Mask

private extension View {
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask(
            ZStack {
                Rectangle()
                mask()
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
        )
    }
}
