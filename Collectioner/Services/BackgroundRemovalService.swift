import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

/// Removes image backgrounds using Apple Vision framework (VNGenerateForegroundInstanceMaskRequest).
/// Runs on-device, no network needed. Only works on physical devices (not Simulator).
final class BackgroundRemovalService: Sendable {

    static let shared = BackgroundRemovalService()

    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    private init() {}

    /// Removes the background from a UIImage, returning a new image with a transparent background.
    /// Returns the original image if processing fails (e.g. on Simulator).
    func removeBackground(from image: UIImage) async -> UIImage {
        let image = image.normalizedOrientation()
        guard let cgImage = image.cgImage else { return image }

        let ciImage = CIImage(cgImage: cgImage)

        guard let mask = await generateMask(from: ciImage) else { return image }

        let masked = applyMask(mask, to: ciImage)

        guard let output = renderToUIImage(masked, size: image.size) else { return image }

        return output
    }

    // MARK: - Pipeline

    private func generateMask(from inputImage: CIImage) async -> CIImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: inputImage, options: [:])

        do {
            try handler.perform([request])

            guard let result = request.results?.first else { return nil }

            let maskPixelBuffer = try result.generateScaledMaskForImage(
                forInstances: result.allInstances,
                from: handler
            )
            return CIImage(cvPixelBuffer: maskPixelBuffer)
        } catch {
            print("[BackgroundRemoval] Mask generation failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func applyMask(_ mask: CIImage, to original: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = original
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage ?? original
    }

    private func renderToUIImage(_ ciImage: CIImage, size: CGSize) -> UIImage? {
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
