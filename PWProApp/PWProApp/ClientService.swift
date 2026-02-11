
import Foundation
import Supabase

@MainActor
class ClientService {
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    func fetchClients() async throws -> [ClientData] {
        let response: [ClientData] = try await client
            .from("clients")
            .select()
            .order("name")
            .execute()
            .value
        return response
    }
    
    func insertClient(_ clientData: ClientData) async throws {
        try await client
            .from("clients")
            .insert(clientData)
            .execute()
    }
    
    func updateClient(_ clientData: ClientData) async throws {
        try await client
            .from("clients")
            .update(clientData)
            .eq("id", value: clientData.id.uuidString)
            .execute()
    }
    
    func deleteClient(id: UUID) async throws {
        try await client
            .from("clients")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Notes
    
    func fetchClientNotes(clientId: UUID) async throws -> [ClientNote] {
        let response: [ClientNote] = try await client
            .from("client_notes")
            .select()
            .eq("client_id", value: clientId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
    
    func insertClientNote(_ note: ClientNote) async throws {
        try await client
            .from("client_notes")
            .insert(note)
            .execute()
    }
}

// MARK: - Data Models

struct ClientData: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    var name: String
    var email: String?
    var phone: String?
    var address: String?
    var rating: Int
    var totalSpent: Double
    var lifetimeJobs: Int
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, email, phone, address, rating
        case totalSpent = "total_spent"
        case lifetimeJobs = "lifetime_jobs"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ClientNote: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    let clientId: UUID
    var note: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case clientId = "client_id"
        case note
        case createdAt = "created_at"
    }
}
