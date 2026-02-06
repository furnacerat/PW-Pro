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
    @Published var stocks: [ChemicalStock] = []
    @Published var isLoading = false
    @Published var error: String?
    
    static let shared = ChemicalInventoryManager()
    private let supabase = SupabaseManager.shared
    private let inventoryService: InventoryService
    
    private init() {
        self.inventoryService = InventoryService(client: SupabaseManager.shared.client)
    }
    
    func fetchChemicals() async {
        isLoading = true
        error = nil
        
        do {
            let chemicalData = try await inventoryService.fetchChemicalInventory()
            
            // Convert Supabase data to app ChemicalStock model
            stocks = chemicalData.compactMap { data in
                // Find matching chemical from ChemicalData
                guard let chemical = ChemicalData.allChemicals.first(where: { $0.name == data.chemicalName }) else {
                    return nil
                }
                
                return ChemicalStock(
                    id: data.id,
                    chemical: chemical,
                    currentGallons: data.currentStock,
                    capacityGallons: 55.0, // Default capacity
                    lowStockThreshold: data.minStockLevel ?? 5.0
                )
            }
            
            // If no chemicals exist, add seed data
            if stocks.isEmpty {
                for chem in ChemicalData.allChemicals.prefix(5) {
                    let stock = ChemicalStock(
                        chemical: chem,
                        currentGallons: Double.random(in: 10...50),
                        capacityGallons: 55.0
                    )
                    await addChemical(stock)
                }
            }
        } catch {
            self.error = error.localizedDescription
            print("Failed to fetch chemicals: \(error)")
        }
        
        isLoading = false
    }
    
    func addChemical(_ stock: ChemicalStock) async {
        // Optimistic update
        stocks.append(stock)
        
        do {
            let chemicalData = ChemicalInventoryData(
                id: stock.id,
                userId: supabase.currentUser?.id,
                chemicalName: stock.chemical.name,
                chemicalType: stock.chemical.category.rawValue,
                currentStock: stock.currentGallons,
                unit: "gallons",
                minStockLevel: stock.lowStockThreshold,
                costPerUnit: nil,
                lastOrdered: nil,
                createdAt: nil,
                updatedAt: nil
            )
            
            try await inventoryService.insertChemical(chemicalData)
        } catch {
            // Rollback on error
            stocks.removeAll { $0.id == stock.id }
            self.error = "Failed to add chemical: \(error.localizedDescription)"
            print("Failed to add chemical: \(error)")
        }
    }
    
    func deductStock(chemicalID: UUID, gallons: Double) {
        if let index = stocks.firstIndex(where: { $0.id == chemicalID }) {
            stocks[index].currentGallons = max(0, stocks[index].currentGallons - gallons)
            
            Task {
                await updateChemical(stocks[index])
            }
        }
    }
    
    func addStock(chemicalID: UUID, gallons: Double) {
        if let index = stocks.firstIndex(where: { $0.id == chemicalID }) {
            stocks[index].currentGallons = min(stocks[index].capacityGallons, stocks[index].currentGallons + gallons)
            
            Task {
                await updateChemical(stocks[index])
            }
        }
    }
    
    private func updateChemical(_ stock: ChemicalStock) async {
        do {
            let chemicalData = ChemicalInventoryData(
                id: stock.id,
                userId: supabase.currentUser?.id,
                chemicalName: stock.chemical.name,
                chemicalType: stock.chemical.category.rawValue,
                currentStock: stock.currentGallons,
                unit: "gallons",
                minStockLevel: stock.lowStockThreshold,
                costPerUnit: nil,
                lastOrdered: nil,
                createdAt: nil,
                updatedAt: nil
            )
            
            try await inventoryService.updateChemical(chemicalData)
        } catch {
            self.error = "Failed to update chemical: \(error.localizedDescription)"
            print("Failed to update chemical: \(error)")
            // Refetch to revert
            await fetchChemicals()
        }
    }
}
