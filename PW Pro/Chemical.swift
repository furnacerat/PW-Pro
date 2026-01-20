import Foundation

struct Chemical: Identifiable, Hashable {
    var id = UUID()
    let name: String
    let shortDescription: String
    let uses: String
    let precautions: String
    let mixingNote: String
    let sdsURL: String?
}
