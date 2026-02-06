
import Foundation
import Supabase

@MainActor
class EstimateService {
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    func fetchEstimates() async throws -> [EstimateData] {
        let response: [EstimateData] = try await client
            .from("estimates")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
    
    func insertEstimate(_ estimate: EstimateData) async throws {
        try await client
            .from("estimates")
            .insert(estimate)
            .execute()
    }
    
    func updateEstimate(_ estimate: EstimateData) async throws {
        try await client
            .from("estimates")
            .update(estimate)
            .eq("id", value: estimate.id.uuidString)
            .execute()
    }
    
    func deleteEstimate(id: UUID) async throws {
        try await client
            .from("estimates")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Data Models

struct EstimateData: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    var clientId: UUID?
    var clientName: String
    var jobName: String
    var totalPrice: Double
    var squareFootage: Double?
    var surfaceType: String?
    var items: [EstimateItemData]
    var status: String
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case clientId = "client_id"
        case clientName = "client_name"
        case jobName = "job_name"
        case totalPrice = "total_price"
        case squareFootage = "square_footage"
        case surfaceType = "surface_type"
        case items, status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct EstimateItemData: Codable {
    var description: String
    var quantity: Double
    var rate: Double
    var total: Double
}
