import Foundation
import SwiftUI

enum EquipmentStatus: String, Codable {
    case healthy = "Healthy"
    case maintenanceRequired = "Maintenance Required"
    case critical = "Critical"
}

struct Equipment: Identifiable, Codable {
    var id = UUID()
    let name: String
    let type: String
    var totalHours: Double
    var nextMaintenanceHours: Double
    var lastMaintenanceDate: Date
    
    var healthScore: Double {
        let remaining = nextMaintenanceHours - totalHours
        if remaining <= 0 { return 0 }
        return min(1.0, remaining / 100.0) // Assume 100hr cycles
    }
    
    var status: EquipmentStatus {
        if healthScore <= 0 { return .critical }
        if healthScore < 0.25 { return .maintenanceRequired }
        return .healthy
    }
}

@MainActor
class EquipmentManager: ObservableObject {
    @Published var equipment: [Equipment] = []
    @Published var isLoading = false
    @Published var error: String?
    
    static let shared = EquipmentManager()
    private let supabase = SupabaseManager.shared
    private let inventoryService: InventoryService
    
    private init() {
        self.inventoryService = InventoryService(client: SupabaseManager.shared.client)
    }
    
    func fetchEquipment() async {
        isLoading = true
        error = nil
        
        do {
            let equipmentData = try await inventoryService.fetchEquipment()
            
            // Convert Supabase data to app Equipment model
            equipment = equipmentData.map { data in
                Equipment(
                    id: data.id,
                    name: data.name,
                    type: data.type,
                    totalHours: data.totalHours,
                    nextMaintenanceHours: data.nextMaintenanceHours,
                    lastMaintenanceDate: data.lastMaintenanceDate ?? Date()
                )
            }
            
            // If no equipment exists and user is logged in, add seed data
            if equipment.isEmpty && supabase.currentUser != nil {
                let mockEquipment = [
                    Equipment(name: "Honda GX390 Washer", type: "Pressure Washer", totalHours: 42.5, nextMaintenanceHours: 50.0, lastMaintenanceDate: Date().addingTimeInterval(-86400 * 30)),
                    Equipment(name: "Tucker Water Fed Pole", type: "Window Cleaning", totalHours: 120.0, nextMaintenanceHours: 200.0, lastMaintenanceDate: Date().addingTimeInterval(-86400 * 60)),
                    Equipment(name: "Surface Cleaner 20\"", type: "Concrete", totalHours: 18.0, nextMaintenanceHours: 50.0, lastMaintenanceDate: Date().addingTimeInterval(-86400 * 15))
                ]
                
                for equip in mockEquipment {
                    await addEquipment(equip)
                }
            }
        } catch {
            self.error = error.localizedDescription
            print("Failed to fetch equipment: \(error)")
        }
        
        isLoading = false
    }
    
    func addEquipment(_ equip: Equipment) async {
        // Optimistic update
        equipment.append(equip)
        
        do {
            let equipmentData = EquipmentData(
                id: equip.id,
                userId: supabase.currentUser?.id,
                name: equip.name,
                type: equip.type,
                totalHours: equip.totalHours,
                nextMaintenanceHours: equip.nextMaintenanceHours,
                lastMaintenanceDate: equip.lastMaintenanceDate,
                createdAt: nil,
                updatedAt: nil
            )
            
            try await inventoryService.insertEquipment(equipmentData)
        } catch {
            // Rollback on error
            equipment.removeAll { $0.id == equip.id }
            self.error = "Failed to add equipment: \(error.localizedDescription)"
            print("Failed to add equipment: \(error)")
        }
    }
    
    func logUsage(hours: Double, for equipmentID: UUID) {
        if let index = equipment.firstIndex(where: { $0.id == equipmentID }) {
            equipment[index].totalHours += hours
            
            Task {
                await updateEquipment(equipment[index])
            }
        }
    }
    
    private func updateEquipment(_ equip: Equipment) async {
        do {
            let equipmentData = EquipmentData(
                id: equip.id,
                userId: supabase.currentUser?.id,
                name: equip.name,
                type: equip.type,
                totalHours: equip.totalHours,
                nextMaintenanceHours: equip.nextMaintenanceHours,
                lastMaintenanceDate: equip.lastMaintenanceDate,
                createdAt: nil,
                updatedAt: nil
            )
            
            try await inventoryService.updateEquipment(equipmentData)
        } catch {
            self.error = "Failed to update equipment: \(error.localizedDescription)"
            print("Failed to update equipment: \(error)")
            // Refetch to revert
            await fetchEquipment()
        }
    }
}
