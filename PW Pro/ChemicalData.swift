import Foundation

struct ChemicalData {
    static var chemicals: [Chemical] = load()

    static func load() -> [Chemical] {
        // Attempt to load bundled JSON first
        if let url = Bundle.main.url(forResource: "chemicals", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let list = try decoder.decode([Chemical].self, from: data)
                return list
            } catch {
                print("Failed to decode chemicals.json: \(error)")
            }
        } else {
            print("chemicals.json not found in bundle — using fallback list")
        }

        // During development, try to load `chemicals.json` from the source tree
        // (uses the compile-time path of this file to locate the repo root).
        let sourceDir = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent()
        let devURL = sourceDir.appendingPathComponent("chemicals.json")
        if FileManager.default.fileExists(atPath: devURL.path) {
            do {
                let data = try Data(contentsOf: devURL)
                let decoder = JSONDecoder()
                let list = try decoder.decode([Chemical].self, from: data)
                print("Loaded chemicals.json from project path: \(devURL.path)")
                return list
            } catch {
                print("Failed to decode chemicals.json from project path: \(error)")
            }
        }

        // Fallback built-in list (minimal examples with brand hints)
        return [
            Chemical(externalID: "chem-001", name: "Sodium Hypochlorite (Bleach)", shortDescription: "Chlorine-based oxidizing bleach used for whitening and disinfection.", uses: "Mildew/mold removal, sanitizing siding, decks, concrete; organic stain removal.", precautions: "Corrosive to skin/eyes; produces toxic gases if mixed with acids or ammonia; wear gloves, goggles, and respirator for fumes; control runoff.", mixingNote: "Typically diluted for surface cleaning; follow product label for concentration.", sdsURL: nil, brands: ["Clorox", "Private Label Bleach"]),
            Chemical(externalID: "chem-002", name: "Sodium Percarbonate (Oxygen Bleach)", shortDescription: "Oxygen-based powdered bleach that releases hydrogen peroxide.", uses: "Brightening wood and concrete; gentler mold/algae removal alternative to chlorine.", precautions: "Oxidizer; eye/skin irritant; keep dry in storage; use gloves and goggles.", mixingNote: "Dissolve per manufacturer's instructions; active at warm temperatures.", sdsURL: nil, brands: ["OxiClean", "Private Label Oxygen Bleach"])        ]
    }
}
