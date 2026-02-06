import Foundation
import UIKit
import CoreImage

/// Lightweight heuristic-based image analyzer used as a prototype
/// Produces surface and contamination suggestions and a rough sqft estimate when possible.
final class AIAnalyzer {
    static func analyze(_ image: UIImage) async -> (surfaces: [String], objects: [String], sqftEstimate: Double?) {
        // Simple color-based heuristics
        guard let ci = CIImage(image: image) else { return ([], [], nil) }

        let context = CIContext(options: nil)
        // Use CIAreaAverage to get average color of the image
        let extent = ci.extent
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        guard let filter = CIFilter(name: "CIAreaAverage") else { return ([], [], nil) }
        filter.setValue(ci, forKey: kCIInputImageKey)
        filter.setValue(inputExtent, forKey: kCIInputExtentKey)
        guard let outputImage = filter.outputImage else { return ([], [], nil) }

        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        let r = Double(bitmap[0]) / 255.0
        let g = Double(bitmap[1]) / 255.0
        let b = Double(bitmap[2]) / 255.0

        var surfaces: [String] = []
        var objects: [String] = []

        // Vegetation heuristic
        if g > r * 1.15 && g > b * 1.15 {
            objects.append("Vegetation")
            surfaces.append("vinyl")
        }

        // Brick / stone warmer tone heuristic
        if r > 0.35 && g > 0.18 && b < 0.25 && r > g && r > b {
            surfaces.append("brick")
        }

        // Smooth / low-contrast -> vinyl or aluminum
        if abs(r - g) < 0.05 && abs(g - b) < 0.05 {
            surfaces.append("aluminum")
            surfaces.append("vinyl")
        }

        // Dark / organic growth guess
        if (r + g + b) / 3.0 < 0.4 {
            objects.append("Organic Growth / Mildew")
        }

        // Rough sqft estimator: use image size as proxy — very approximate
        let pxArea = Double(image.size.width * image.size.height)
        let sqftEstimate = max(0.0, min(20000.0, pxArea / 1000.0))

        // De-duplicate preserving order
        surfaces = Array(NSOrderedSet(array: surfaces)) as! [String]
        objects = Array(NSOrderedSet(array: objects)) as! [String]

        return (surfaces, objects, sqftEstimate)
    }
}
