
import Foundation
import Supabase

@MainActor
class InvoiceService {
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    func fetchInvoices() async throws -> [InvoiceData] {
        let response: [InvoiceData] = try await client
            .from("invoices")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
    
    func insertInvoice(_ invoice: InvoiceData) async throws {
        try await client
            .from("invoices")
            .insert(invoice)
            .execute()
    }
    
    func updateInvoice(_ invoice: InvoiceData) async throws {
        try await client
            .from("invoices")
            .update(invoice)
            .eq("id", value: invoice.id.uuidString)
            .execute()
    }
    
    func deleteInvoice(id: UUID) async throws {
        try await client
            .from("invoices")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

// MARK: - Data Models

struct InvoiceData: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    var clientId: UUID?
    var clientName: String
    var clientEmail: String?
    var clientPhone: String?
    var invoiceNumber: String
    var issueDate: Date
    var dueDate: Date
    var items: [InvoiceItemData]
    var subtotal: Double
    var tax: Double
    var total: Double
    var status: String
    var notes: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case clientId = "client_id"
        case clientName = "client_name"
        case clientEmail = "client_email"
        case clientPhone = "client_phone"
        case invoiceNumber = "invoice_number"
        case issueDate = "issue_date"
        case dueDate = "due_date"
        case items, subtotal, tax, total, status, notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct InvoiceItemData: Codable {
    var description: String
    var quantity: Double
    var rate: Double
    var amount: Double
}
