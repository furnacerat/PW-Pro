import Foundation
import SwiftUI

enum PaymentProvider: String, Codable, CaseIterable {
    case stripe = "Stripe"
    case square = "Square"
    case paypal = "PayPal"
    case custom = "Custom Link"
    
    var icon: String {
        switch self {
        case .stripe: return "creditcard.fill"
        case .square: return "square.fill"
        case .paypal: return "p.circle.fill"
        case .custom: return "link"
        }
    }
}

struct BusinessSettings: Codable {
    var businessName: String = "My Pressure Washing Co."
    var businessEmail: String = "pro@example.com"
    var businessPhone: String = "(555) 000-0000"
    var businessAddress: String = "123 Business Way, City, ST"
    var paymentProvider: PaymentProvider = .custom
    var paymentLink: String = ""
    var customTerms: String = "All work is performed to industry standards. Payment due upon completion."
    var logoData: Data? = nil
    var googleReviewLink: String = ""
    
    static let shared = BusinessSettings()
}

enum InvoiceStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case sent = "Sent"
    case paid = "Paid"
    case overdue = "Overdue"
    
    var color: Color {
        switch self {
        case .draft: return Theme.slate500
        case .sent: return Theme.sky500
        case .paid: return Theme.emerald500
        case .overdue: return Theme.red500
        }
    }
}

struct InvoiceItem: Identifiable, Codable {
    var id = UUID()
    let description: String
    let quantity: Double
    let rate: Double
    let amount: Double
}

struct Invoice: Identifiable, Codable {
    var id = UUID()
    let estimateID: UUID?
    let clientName: String
    let clientEmail: String
    let clientAddress: String
    let date: Date
    var status: InvoiceStatus
    var items: [InvoiceItem]
    let total: Double
    var paymentLink: String
    
    var invoiceNumber: String {
        "INV-\(String(id.uuidString.prefix(6)).uppercased())"
    }
}

@MainActor
class InvoiceManager: ObservableObject {
    @Published var invoices: [Invoice] = []
    @Published var businessSettings = BusinessSettings() {
        didSet { saveSettings() } // Keep settings local for now
    }
    @Published var isLoading = false
    @Published var error: String?
    
    private let settingsFile = "settings.json"
    static let shared = InvoiceManager()
    private let supabase = SupabaseManager.shared
    private let invoiceService: InvoiceService
    
    private init() {
        self.invoiceService = InvoiceService(client: SupabaseManager.shared.client)
        loadSettings()
    }
    
    func fetchInvoices() async {
        isLoading = true
        error = nil
        
        do {
            let invoiceDataList = try await invoiceService.fetchInvoices()
            
            self.invoices = invoiceDataList.map { data in
                // Map InvoiceItemData -> InvoiceItem
                let items = data.items.map { itemData in
                    InvoiceItem(
                        id: UUID(), // Not persisted individually in InvoiceData
                        description: itemData.description,
                        quantity: itemData.quantity,
                        rate: itemData.rate,
                        amount: itemData.amount
                    )
                }
                
                return Invoice(
                    id: data.id,
                    estimateID: nil, // Not persisted in InvoiceData currently
                    clientName: data.clientName,
                    clientEmail: data.clientEmail ?? "",
                    clientAddress: "", // Metadata not in InvoiceData
                    date: data.issueDate,
                    status: InvoiceStatus(rawValue: data.status) ?? .draft,
                    items: items,
                    total: data.total,
                    paymentLink: "" // Metadata not in InvoiceData
                )
            }
        } catch {
            print("Error fetching invoices: \(error)")
            self.error = "Failed to load invoices."
        }
        
        isLoading = false
    }
    
    func createInvoice(from estimate: Estimate, for client: Client, totalPrice: Double? = nil) {
        Task {
            await addInvoice(from: estimate, for: client, totalPrice: totalPrice)
        }
    }
            
    func addInvoice(from estimate: Estimate, for client: Client, totalPrice: Double? = nil) async {
        isLoading = true
        
        let items = estimate.items.map { item in
            InvoiceItem(
                description: "\(item.displayName) (\(Int(item.squareFootage)) sq ft)",
                quantity: 1,
                rate: 0,
                amount: item.squareFootage * (estimate.pricingModel == .perSquareFoot ? estimate.pricePerSqFt : 0.15)
            )
        }
        
        let calculatedTotal = totalPrice ?? items.reduce(0) { $0 + $1.amount }
        let newId = UUID()
        let status = InvoiceStatus.draft
        
        // 1. Map to Supabase Data
        let itemsData = items.map { item in
            InvoiceItemData(
                description: item.description,
                quantity: item.quantity,
                rate: item.rate,
                amount: item.amount
            )
        }
        
        let invoiceData = InvoiceData(
            id: newId,
            userId: supabase.currentUser?.id,
            clientId: client.id,
            clientName: client.name,
            clientEmail: client.email,
            clientPhone: client.phone,
            invoiceNumber: "INV-\(String(newId.uuidString.prefix(6)).uppercased())",
            issueDate: Date(),
            dueDate: Date().addingTimeInterval(86400 * 30), // 30 days
            items: itemsData,
            subtotal: calculatedTotal, // Simplified
            tax: 0,
            total: calculatedTotal,
            status: status.rawValue,
            notes: "Thank you for your business!",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // 2. Optimistic Update
        let newInvoice = Invoice(
            id: newId,
            estimateID: estimate.id,
            clientName: client.name,
            clientEmail: client.email,
            clientAddress: client.address,
            date: Date(),
            status: status,
            items: items,
            total: calculatedTotal,
            paymentLink: businessSettings.paymentLink
        )
        self.invoices.append(newInvoice)
        
        // 3. Persist
        do {
            try await invoiceService.insertInvoice(invoiceData)
        } catch {
            print("Error saving invoice: \(error)")
            self.error = "Failed to save invoice to cloud."
        }
        
        isLoading = false
    }
    
    func getInvoice(id: UUID) -> Invoice? {
        invoices.first { $0.id == id }
    }
    
    func deleteInvoice(_ invoice: Invoice) {
        Task {
            // Optimistic
            invoices.removeAll { $0.id == invoice.id }
            
            do {
                try await invoiceService.deleteInvoice(id: invoice.id)
            } catch {
                print("Error deleting invoice: \(error)")
                self.error = "Failed to delete invoice"
                // Revert
                await fetchInvoices()
            }
        }
    }
    
    // MARK: - Business Settings (Local Only)
    
    private func saveSettings() {
        StorageManager.shared.save(businessSettings, to: settingsFile)
    }
    
    private func loadSettings() {
        if let loaded: BusinessSettings = StorageManager.shared.load(BusinessSettings.self, from: settingsFile) {
            self.businessSettings = loaded
        }
    }
}
