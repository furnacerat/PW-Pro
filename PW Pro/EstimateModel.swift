import Foundation
import SwiftUI

struct Estimate: Identifiable, Codable, Hashable {
    enum SurfaceType: String, CaseIterable, Codable {
        case vinyl, aluminum, brick, concrete, wood, stone, unknown
        var displayName: String { rawValue.capitalized }
    }

    enum Contamination: String, CaseIterable, Codable {
        case organic, oil, dirt, paint, mildew, unknown
        var displayName: String { rawValue.capitalized }
    }

    var id = UUID()
    // Optional customer / property info
    var propertyOwnerName: String? = nil
    var propertyAddress: String? = nil
    var scopeOfWork: String = ""
    var approved: Bool = false
    var scheduledDate: Date? = nil
    var surface: SurfaceType = .unknown
    var contamination: Contamination = .unknown
    var sqft: Double = 0
    var notes: String = ""
    var imageAttached: Bool = false
    var warnings: [String] = []
    var recommendation: String = ""
    // Optional stored images for before/after comparison
    var beforeImageData: Data? = nil
    var afterImageData: Data? = nil
}

struct RecommendationResult {
    let recommendation: String
    let warnings: [String]
    let sqftEstimate: Double?
}
