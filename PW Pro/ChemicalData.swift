import Foundation

struct ChemicalData {
    static var chemicals: [Chemical] = load()

    static func load() -> [Chemical] {
        let decoder = JSONDecoder()

        // 1) Try bundled resource (app bundle)
        if let bundleURL = Bundle.main.url(forResource: "chemicals", withExtension: "json") {
            do {
                let data = try Data(contentsOf: bundleURL)
                let list = try decoder.decode([Chemical].self, from: data)
                print("Loaded \(list.count) chemicals from app bundle")
                return list
            } catch {
                print("Failed to decode bundled chemicals.json: \(error)")
            }
        }

        // 2) Try to locate chemicals.json in the repo/source tree near this file
        var searchURL = URL(fileURLWithPath: #file).deletingLastPathComponent()
        // Walk up a few directories to find the repo root
        for _ in 0..<6 {
            let candidate = searchURL.appendingPathComponent("chemicals.json")
            if FileManager.default.fileExists(atPath: candidate.path) {
                do {
                    let data = try Data(contentsOf: candidate)
                    let list = try decoder.decode([Chemical].self, from: data)
                    print("Loaded \(list.count) chemicals from project path: \(candidate.path)")
                    return list
                } catch {
                    print("Failed to decode chemicals.json at \(candidate.path): \(error)")
                }
            }
            searchURL.deleteLastPathComponent()
        }

        // 3) Try current working directory as a last developer convenience
        let cwdCandidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("chemicals.json")
        if FileManager.default.fileExists(atPath: cwdCandidate.path) {
            do {
                let data = try Data(contentsOf: cwdCandidate)
                let list = try decoder.decode([Chemical].self, from: data)
                print("Loaded \(list.count) chemicals from CWD: \(cwdCandidate.path)")
                return list
            } catch {
                print("Failed to decode chemicals.json from CWD: \(error)")
            }
        }

        // 4) Fallback minimal list so the app has something to display
        print("chemicals.json not found — using built-in fallback list (2 items)")
        return [
            Chemical(externalID: "chem-001", name: "Sodium Hypochlorite (Bleach)", shortDescription: "Chlorine-based oxidizing bleach used for whitening and disinfection.", uses: "Mildew/mold removal, sanitizing siding, decks, concrete; organic stain removal.", precautions: "Corrosive to skin/eyes; produces toxic gases if mixed with acids or ammonia; wear gloves, goggles, and respirator for fumes; control runoff.", mixingNote: "Typically diluted for surface cleaning; follow product label for concentration.", sdsURL: nil, brands: ["Clorox", "Private Label Bleach"]),
            Chemical(externalID: "chem-002", name: "Sodium Percarbonate (Oxygen Bleach)", shortDescription: "Oxygen-based powdered bleach that releases hydrogen peroxide.", uses: "Brightening wood and concrete; gentler mold/algae removal alternative to chlorine.", precautions: "Oxidizer; eye/skin irritant; keep dry in storage; use gloves and goggles.", mixingNote: "Dissolve per manufacturer's instructions; active at warm temperatures.", sdsURL: nil, brands: ["OxiClean", "Private Label Oxygen Bleach"])        ]
    }
}
