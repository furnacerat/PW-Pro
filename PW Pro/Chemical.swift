import Foundation

struct Chemical: Identifiable, Hashable, Codable {
    var id = UUID()
    let externalID: String?
    let name: String
    let shortDescription: String
    let uses: String
    let precautions: String
    let mixingNote: String
    let sdsURL: String?
    let brands: [String]?

    enum CodingKeys: String, CodingKey {
        case externalID = "id"
        case name, shortDescription, uses, precautions, mixingNote, sdsURL, brands
    }
}
