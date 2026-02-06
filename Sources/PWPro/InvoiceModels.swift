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

enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "Cash"
    case check = "Check"
    case creditCard = "Credit Card"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .cash: return "dollarsign.circle.fill"
        case .check: return "checkmark.rectangle.fill"
        case .creditCard: return "creditcard.fill"
        case .other: return "ellipsis.circle.fill"
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
    
    // Payment tracking (optional for backward compatibility)
    var paymentMethod: PaymentMethod?
    var paidDate: Date?
    var checkNumber: String?
    
    var invoiceNumber: String {
        "INV-\(String(id.uuidString.prefix(6)).uppercased())"
    }
    
    var receiptNumber: String {
        "REC-\(String(id.uuidString.prefix(6)).uppercased())"
    }
}

@MainActor
class InvoiceManager: ObservableObject {
    @Published var invoices: [Invoice] = [] {
        didSet { saveInvoices() }
    }
    @Published var businessSettings = BusinessSettings() {
        didSet { saveSettings() }
    }
    
    private let invoicesFile = "invoices.json"
    private let settingsFile = "settings.json"
    
    static let shared = InvoiceManager()
    
    private init() {
        loadInvoices()
        loadSettings()
    }
    
    private func saveInvoices() {
        StorageManager.shared.save(invoices, to: invoicesFile)
    }
    
    private func saveSettings() {
        StorageManager.shared.save(businessSettings, to: settingsFile)
    }
    
    private func loadInvoices() {
        if let loaded: [Invoice] = StorageManager.shared.load([Invoice].self, from: invoicesFile) {
            self.invoices = loaded
        }
    }
    
    private func loadSettings() {
        if let loaded: BusinessSettings = StorageManager.shared.load(BusinessSettings.self, from: settingsFile) {
            self.businessSettings = loaded
        }
    }
    
    func createInvoice(from estimate: Estimate, for client: Client, totalPrice: Double) -> Invoice {
        // Calculate total square footage to distribute the price proportionally
        let totalSqFt = estimate.items.reduce(0) { $0 + $1.squareFootage }
        
        // Create invoice items with amounts proportional to their square footage
        let items = estimate.items.map { item in
            let proportion = totalSqFt > 0 ? item.squareFootage / totalSqFt : 0
            let itemAmount = totalPrice * proportion
            
            return InvoiceItem(
                description: "\(item.displayName) (\(Int(item.squareFootage)) sq ft)",
                quantity: 1,
                rate: itemAmount,
                amount: itemAmount
            )
        }
        
        let newInvoice = Invoice(
            estimateID: estimate.id,
            clientName: client.name,
            clientEmail: client.email,
            clientAddress: client.address,
            date: Date(),
            status: .draft,
            items: items,
            total: totalPrice,
            paymentLink: businessSettings.paymentLink
        )
        
        invoices.append(newInvoice)
        return newInvoice
    }
    
    func getInvoice(id: UUID) -> Invoice? {
        invoices.first { $0.id == id }
    }
    
    func markAsPaid(invoiceId: UUID, method: PaymentMethod, checkNumber: String? = nil) {
        guard let index = invoices.firstIndex(where: { $0.id == invoiceId }) else { return }
        
        invoices[index].status = .paid
        invoices[index].paymentMethod = method
        invoices[index].paidDate = Date()
        
        if method == .check {
            invoices[index].checkNumber = checkNumber
        }
        
        // Changes will auto-save via didSet
    }
    
    // Helper to match logic in EstimatorView
    private func calculateEstimatePrice(_ estimate: Estimate) -> Double {
        let totalSqFt = estimate.items.reduce(0) { $0 + $1.squareFootage }
        switch estimate.pricingModel {
        case .perSquareFoot:
            return totalSqFt * estimate.pricePerSqFt
        case .costPlus:
            return (estimate.laborHours * estimate.hourlyRate) + 200 
        }
    }
}
