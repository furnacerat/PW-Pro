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
    @Published var equipment: [Equipment] = [] {
        didSet { save() }
    }
    
    private let filename = "equipment.json"
    static let shared = EquipmentManager()
    
    private init() {
        load()
        if equipment.isEmpty {
            self.equipment = [
                Equipment(name: "Honda GX390 Washer", type: "Pressure Washer", totalHours: 42.5, nextMaintenanceHours: 50.0, lastMaintenanceDate: Date().addingTimeInterval(-86400 * 30)),
                Equipment(name: "Tucker Water Fed Pole", type: "Window Cleaning", totalHours: 120.0, nextMaintenanceHours: 200.0, lastMaintenanceDate: Date().addingTimeInterval(-86400 * 60)),
                Equipment(name: "Surface Cleaner 20\"", type: "Concrete", totalHours: 18.0, nextMaintenanceHours: 50.0, lastMaintenanceDate: Date().addingTimeInterval(-86400 * 15))
            ]
            save()
        }
    }
    
    func logUsage(hours: Double, for equipmentID: UUID) {
        if let index = equipment.firstIndex(where: { $0.id == equipmentID }) {
            equipment[index].totalHours += hours
            save()
        }
    }
    
    func save() {
        StorageManager.shared.save(equipment, to: filename)
    }
    
    private func load() {
        if let loaded: [Equipment] = StorageManager.shared.load([Equipment].self, from: filename) {
            self.equipment = loaded
        }
    }
}
