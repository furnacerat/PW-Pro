
import Foundation
import Supabase

@MainActor
class JobService {
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    func fetchJobs() async throws -> [JobData] {
        let response: [JobData] = try await client
            .from("jobs")
            .select()
            .order("date", ascending: false)
            .execute()
            .value
        return response
    }
    
    func insertJob(_ job: JobData) async throws {
        try await client
            .from("jobs")
            .insert(job)
            .execute()
    }
    
    func updateJob(_ job: JobData) async throws {
        try await client
            .from("jobs")
            .update(job)
            .eq("id", value: job.id.uuidString)
            .execute()
    }
    
    func deleteJob(id: UUID) async throws {
        try await client
            .from("jobs")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Data Models

struct JobData: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    var clientId: UUID?
    var clientName: String
    var serviceType: String
    var date: Date
    var status: String
    var address: String?
    var notes: String?
    var price: Double?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case clientId = "client_id"
        case clientName = "client_name"
        case serviceType = "service_type"
        case date, status, address, notes, price
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
