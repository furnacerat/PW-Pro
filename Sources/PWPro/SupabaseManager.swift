import Foundation
import Supabase

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {
        let configService = ConfigurationService.shared
        
        client = SupabaseClient(
            supabaseURL: configService.supabaseURL,
            supabaseKey: configService.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
        
        Task {
            await checkSession()
        }
    }
    
    // MARK: - Authentication
    
    func checkSession() async {
        do {
            let session = try await client.auth.session
            
            if session.isExpired {
                print("Session expired")
                isAuthenticated = false
                currentUser = nil
                return
            }
            
            currentUser = session.user
            isAuthenticated = true
            print("Session valid for user: \(currentUser?.email ?? "unknown")")
        } catch {
            print("No active session: \(error.localizedDescription)")
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    func signUp(email: String, password: String, fullName: String? = nil) async throws {
        isLoading = true
        error = nil
        
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: fullName != nil ? ["full_name": fullName!] : [:]
            )
            currentUser = response.user
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
            throw error
        } finally {
            isLoading = false
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        error = nil
        
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            currentUser = session.user
            isAuthenticated = true
        } catch {
            self.error = error.localizedDescription
            throw error
        } finally {
            isLoading = false
        }
    }
    
    func signOut() async throws {
        isLoading = true
        error = nil
        
        do {
            try await client.auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            self.error = error.localizedDescription
            throw error
        } finally {
            isLoading = false
        }
    }
    
    func resetPassword(email: String) async throws {
        isLoading = true
        error = nil
        
        do {
            try await client.auth.resetPasswordForEmail(email)
        } catch {
            self.error = error.localizedDescription
            throw error
        } finally {
            isLoading = false
        }
    }
    
    // MARK: - Generic Database Operations
    
    func fetch<T: Codable>(_ type: T.Type, from table: String, filter: some SupabaseFilterable) async throws -> [T] {
        isLoading = true
        error = nil
        
        do {
            let response: [T] = try await client.database
                .from(table)
                .select()
                .eq(filter)
                .execute()
                .value
            return response
        } catch {
            self.error = "Failed to fetch from \(table): \(error.localizedDescription)"
            throw error
        } finally {
            isLoading = false
        }
    }
    
    func insert<T: Codable>(_ data: T, into table: String) async throws -> T {
        isLoading = true
        error = nil
        
        do {
            let response: [T] = try await client.database
                .from(table)
                .insert(data)
                .select()
                .execute()
                .value
            
            guard let inserted = response.first else {
                throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Insert failed"])
            }
            
            return inserted
        } catch {
            self.error = "Failed to insert into \(table): \(error.localizedDescription)"
            throw error
        } finally {
            isLoading = false
        }
    }
    
    func update<T: Codable>(_ data: T, in table: String, filter: some SupabaseFilterable) async throws -> [T] {
        isLoading = true
        error = nil
        
        do {
            let response: [T] = try await client.database
                .from(table)
                .update(data)
                .eq(filter)
                .select()
                .execute()
                .value
            
            return response
        } catch {
            self.error = "Failed to update in \(table): \(error.localizedDescription)"
            throw error
        } finally {
            isLoading = false
        }
    }
    
    func delete(from table: String, filter: some SupabaseFilterable) async throws {
        isLoading = true
        error = nil
        
        do {
            try await client.database
                .from(table)
                .delete()
                .eq(filter)
                .execute()
        } catch {
            self.error = "Failed to delete from \(table): \(error.localizedDescription)"
            throw error
        } finally {
            isLoading = false
        }
    }
    
    // MARK: - User Profile Management
    
    func getCurrentUserProfile() async throws -> UserProfile? {
        guard let userId = currentUser?.id else { return nil }
        
        do {
            let profiles: [UserProfile] = try await client.database
                .from("user_profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            return profiles.first
        } catch {
            self.error = "Failed to fetch user profile: \(error.localizedDescription)"
            throw error
        }
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        isLoading = true
        error = nil
        
        do {
            let profiles: [UserProfile] = try await client.database
                .from("user_profiles")
                .update(profile)
                .eq("id", value: profile.id.uuidString)
                .select()
                .execute()
                .value
            
            guard let updated = profiles.first else {
                throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Profile update failed"])
            }
            
            return updated
        } catch {
            self.error = "Failed to update profile: \(error.localizedDescription)"
            throw error
        } finally {
            isLoading = false
        }
    }
    
    // MARK: - Sync Operations
    
    func syncClients() async throws -> [Client] {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await fetch(Client.self, from: "clients", filter: "user_id" == userId.uuidString)
    }
    
    func syncJobs() async throws -> [Job] {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await fetch(Job.self, from: "jobs", filter: "user_id" == userId.uuidString)
    }
    
    func syncEstimates() async throws -> [Estimate] {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await fetch(Estimate.self, from: "estimates", filter: "user_id" == userId.uuidString)
    }
    
    func syncInvoices() async throws -> [Invoice] {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await fetch(Invoice.self, from: "invoices", filter: "user_id" == userId.uuidString)
    }
    
    func syncEquipment() async throws -> [Equipment] {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await fetch(Equipment.self, from: "equipment", filter: "user_id" == userId.uuidString)
    }
    
    func syncChemicalInventory() async throws -> [ChemicalInventory] {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await fetch(ChemicalInventory.self, from: "chemical_inventory", filter: "user_id" == userId.uuidString)
    }
    
    func syncExpenses() async throws -> [Expense] {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await fetch(Expense.self, from: "expenses", filter: "user_id" == userId.uuidString)
    }
    
    func syncLeads() async throws -> [Lead] {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        return try await fetch(Lead.self, from: "leads", filter: "user_id" == userId.uuidString)
    }
    
    func syncChemicals() async throws -> [Chemical] {
        return try await fetch(Chemical.self, from: "chemicals", filter: "id" == "id") // Get all chemicals
    }
    
    // MARK: - Business Settings
    
    func getBusinessSettings() async throws -> BusinessSettings? {
        guard let userId = currentUser?.id else { return nil }
        
        do {
            let settings: [BusinessSettings] = try await client.database
                .from("business_settings")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            return settings.first
        } catch {
            self.error = "Failed to fetch business settings: \(error.localizedDescription)"
            throw error
        }
    }
    
    func updateBusinessSettings(_ settings: BusinessSettings) async throws -> BusinessSettings {
        isLoading = true
        error = nil
        
        do {
            let existingSettings: [BusinessSettings] = try await client.database
                .from("business_settings")
                .select()
                .eq("user_id", value: settings.user_id.uuidString)
                .execute()
                .value
            
            if let existing = existingSettings.first {
                // Update existing
                let updated: [BusinessSettings] = try await client.database
                    .from("business_settings")
                    .update(settings)
                    .eq("id", value: existing.id.uuidString)
                    .select()
                    .execute()
                    .value
                
                guard let result = updated.first else {
                    throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Settings update failed"])
                }
                return result
            } else {
                // Insert new
                let inserted: [BusinessSettings] = try await client.database
                    .from("business_settings")
                    .insert(settings)
                    .select()
                    .execute()
                    .value
                
                guard let result = inserted.first else {
                    throw NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Settings creation failed"])
                }
                return result
            }
        } catch {
            self.error = "Failed to update business settings: \(error.localizedDescription)"
            throw error
        } finally {
            isLoading = false
        }
    }
}

// MARK: - Data Models for Supabase

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let email: String
    var fullName: String?
    var companyName: String?
    var phone: String?
    var role: String
    var businessAddress: [String: String]?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email, fullName = "full_name", companyName = "company_name"
        case phone, role, businessAddress = "business_address"
        case createdAt = "created_at", updatedAt = "updated_at"
    }
}

struct Client: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var name: String
    var email: String?
    var phone: String?
    var address: [String: String]?
    var notes: String?
    var tags: [String]?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", name, email, phone, address, notes, tags
        case createdAt = "created_at", updatedAt = "updated_at"
    }
}

struct Job: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var clientId: UUID?
    var title: String
    var description: String?
    var status: String
    var price: Double?
    var durationHours: Int?
    var scheduledAt: Date?
    var completedAt: Date?
    var weatherData: [String: Any]?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", clientId = "client_id", title, description, status
        case price, durationHours = "duration_hours", scheduledAt = "scheduled_at"
        case completedAt = "completed_at", weatherData = "weather_data", notes
        case createdAt = "created_at", updatedAt = "updated_at"
    }
}

struct Estimate: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var clientId: UUID?
    var title: String
    var description: String?
    var totalAmount: Double?
    var status: String
    var validUntil: Date?
    var lineItems: [[String: Any]]?
    var propertyData: [String: Any]?
    var aiAnalysis: [String: Any]?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", clientId = "client_id", title, description
        case totalAmount = "total_amount", status, validUntil = "valid_until"
        case lineItems = "line_items", propertyData = "property_data"
        case aiAnalysis = "ai_analysis", createdAt = "created_at", updatedAt = "updated_at"
    }
}

struct Invoice: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var clientId: UUID?
    var jobId: UUID?
    var estimateId: UUID?
    var invoiceNumber: String
    var totalAmount: Double?
    var status: String
    var dueDate: Date?
    var paidDate: Date?
    var lineItems: [[String: Any]]?
    var paymentMethod: String?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", clientId = "client_id", jobId = "job_id"
        case estimateId = "estimate_id", invoiceNumber = "invoice_number"
        case totalAmount = "total_amount", status, dueDate = "due_date"
        case paidDate = "paid_date", lineItems = "line_items"
        case paymentMethod = "payment_method", createdAt = "created_at", updatedAt = "updated_at"
    }
}

struct Equipment: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var name: String
    var type: String?
    var model: String?
    var serialNumber: String?
    var purchaseDate: Date?
    var purchasePrice: Double?
    var maintenanceDue: Date?
    var healthScore: Int?
    var status: String
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", name, type, model, serialNumber = "serial_number"
        case purchaseDate = "purchase_date", purchasePrice = "purchase_price"
        case maintenanceDue = "maintenance_due", healthScore = "health_score", status
        case createdAt = "created_at", updatedAt = "updated_at"
    }
}

struct ChemicalInventory: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var chemicalId: UUID?
    var quantityOnHand: Double?
    var unit: String?
    var reorderLevel: Double?
    var costPerUnit: Double?
    var lastRestocked: Date?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", chemicalId = "chemical_id"
        case quantityOnHand = "quantity_on_hand", unit, reorderLevel = "reorder_level"
        case costPerUnit = "cost_per_unit", lastRestocked = "last_restocked"
        case createdAt = "created_at", updatedAt = "updated_at"
    }
}

struct Chemical: Codable, Identifiable {
    let id: UUID
    var name: String
    var shortDescription: String?
    var uses: String?
    var precautions: String?
    var mixingNote: String?
    var sdsUrl: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, shortDescription = "short_description", uses, precautions
        case mixingNote = "mixing_note", sdsUrl = "sds_url", createdAt = "created_at"
    }
}

struct Expense: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var description: String
    var amount: Double
    var category: String
    var receiptUrl: String?
    var date: Date
    var notes: String?
    var jobId: UUID?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", description, amount, category, receiptUrl = "receipt_url"
        case date, notes, jobId = "job_id", createdAt = "created_at", updatedAt = "updated_at"
    }
}

struct BusinessSettings: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var companyName: String
    var logoUrl: String?
    var contactInfo: [String: String]?
    var businessHours: [String: String]?
    var taxRate: Double?
    var paymentMethods: [String]?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", companyName = "company_name", logoUrl = "logo_url"
        case contactInfo = "contact_info", businessHours = "business_hours"
        case taxRate = "tax_rate", paymentMethods = "payment_methods"
        case createdAt = "created_at", updatedAt = "updated_at"
    }
}

struct Lead: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var clientId: UUID?
    var source: String?
    var status: String
    var priority: String
    var estimatedValue: Double?
    var notes: String?
    var followUpDate: Date?
    var convertedToJobAt: Date?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", clientId = "client_id", source, status, priority
        case estimatedValue = "estimated_value", notes, followUpDate = "follow_up_date"
        case convertedToJobAt = "converted_to_job_at", createdAt = "created_at", updatedAt = "updated_at"
    }
}

// Custom coding for Any type in JSON
extension KeyedDecodingContainer where Key: CodingKey {
    func decodeIfPresent(_ type: [String: Any].Type, forKey key: Key) throws -> [String: Any]? {
        return try decodeIfPresent([String: String].self, forKey: key)
    }
}

extension KeyedEncodingContainer where Key: CodingKey {
    mutating func encodeIfPresent(_ value: [String: Any]?, forKey key: Key) throws {
        try encodeIfPresent(value?.mapValues { String(describing: $0) }, forKey: key)
    }
}