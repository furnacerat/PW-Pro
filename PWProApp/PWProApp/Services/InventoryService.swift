
import Foundation
import Supabase

@MainActor
class InventoryService {
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    // MARK: - Chemicals
    
    func fetchChemicalInventory() async throws -> [ChemicalInventoryData] {
        let response: [ChemicalInventoryData] = try await client
            .from("chemical_inventory")
            .select()
            .order("chemical_name")
            .execute()
            .value
        return response
    }
    
    func insertChemical(_ chemical: ChemicalInventoryData) async throws {
        try await client
            .from("chemical_inventory")
            .insert(chemical)
            .execute()
    }
    
    func updateChemical(_ chemical: ChemicalInventoryData) async throws {
        try await client
            .from("chemical_inventory")
            .update(chemical)
            .eq("id", value: chemical.id.uuidString)
            .execute()
    }
    
    func deleteChemical(id: UUID) async throws {
        try await client
            .from("chemical_inventory")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Equipment
    
    func fetchEquipment() async throws -> [EquipmentData] {
        let response: [EquipmentData] = try await client
            .from("equipment")
            .select()
            .order("name")
            .execute()
            .value
        return response
    }
    
    func insertEquipment(_ equipment: EquipmentData) async throws {
        try await client
            .from("equipment")
            .insert(equipment)
            .execute()
    }
    
    func updateEquipment(_ equipment: EquipmentData) async throws {
        try await client
            .from("equipment")
            .update(equipment)
            .eq("id", value: equipment.id.uuidString)
            .execute()
    }
    
    func deleteEquipment(id: UUID) async throws {
        try await client
            .from("equipment")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Data Models

struct ChemicalInventoryData: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    var chemicalName: String
    var chemicalType: String
    var currentStock: Double
    var unit: String
    var minStockLevel: Double?
    var costPerUnit: Double?
    var lastOrdered: Date?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case chemicalName = "chemical_name"
        case chemicalType = "chemical_type"
        case currentStock = "current_stock"
        case unit
        case minStockLevel = "min_stock_level"
        case costPerUnit = "cost_per_unit"
        case lastOrdered = "last_ordered"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct EquipmentData: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    var name: String
    var type: String
    var totalHours: Double
    var nextMaintenanceHours: Double
    var lastMaintenanceDate: Date?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, type
        case totalHours = "total_hours"
        case nextMaintenanceHours = "next_maintenance_hours"
        case lastMaintenanceDate = "last_maintenance_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
