import Foundation
import SwiftUI

struct ChemicalStock: Identifiable, Codable {
    var id = UUID()
    let chemical: Chemical
    var currentGallons: Double
    var capacityGallons: Double
    var lowStockThreshold: Double = 5.0
    
    var fillPercentage: Double {
        currentGallons / capacityGallons
    }
}

@MainActor
class ChemicalInventoryManager: ObservableObject {
    @Published var stocks: [ChemicalStock] = [] {
        didSet { save() }
    }
    
    private let filename = "chemical_inventory.json"
    static let shared = ChemicalInventoryManager()
    
    private init() {
        load()
        if stocks.isEmpty {
            // Seed with top chemicals
            self.stocks = ChemicalData.allChemicals.prefix(5).map { chem in
                ChemicalStock(chemical: chem, currentGallons: Double.random(in: 10...50), capacityGallons: 55.0)
            }
            save()
        }
    }
    
    func deductStock(chemicalID: UUID, gallons: Double) {
        if let index = stocks.firstIndex(where: { $0.chemical.id == chemicalID }) {
            stocks[index].currentGallons = max(0, stocks[index].currentGallons - gallons)
            save()
        }
    }
    
    func addStock(chemicalID: UUID, gallons: Double) {
        if let index = stocks.firstIndex(where: { $0.chemical.id == chemicalID }) {
            stocks[index].currentGallons = min(stocks[index].capacityGallons, stocks[index].currentGallons + gallons)
            save()
        }
    }
    
    func save() {
        StorageManager.shared.save(stocks, to: filename)
    }
    
    private func load() {
        if let loaded: [ChemicalStock] = StorageManager.shared.load([ChemicalStock].self, from: filename) {
            self.stocks = loaded
        }
    }
}
