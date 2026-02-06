import SwiftUI

enum EstimateStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case sent = "Sent"
    case approved = "Approved"
    case rejected = "Rejected"
    case partial = "Partial"
    
    var color: Color {
        switch self {
        case .draft: return Theme.slate500
        case .sent: return Theme.sky500
        case .approved: return Theme.emerald500
        case .rejected: return Theme.red500
        case .partial: return Theme.amber500
        }
    }
    
    var icon: String {
        switch self {
        case .draft: return "doc.text"
        case .sent: return "paperplane.fill"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .partial: return "checkmark.circle.badge.questionmark.fill"
        }
    }
}

struct SavedEstimate: Identifiable, Codable {
    var id = UUID()
    let estimate: Estimate
    let client: Client
    let totalPrice: Double
    var status: EstimateStatus
    let dateSent: Date?
    var dateResponded: Date?
    var customerNotes: String?
    var selectedItemIds: Set<UUID>? // For partial approvals
    
    var displayDate: Date {
        dateResponded ?? dateSent ?? Date()
    }
}

@MainActor
class EstimateManager: ObservableObject {
    static let shared = EstimateManager()
    
    @Published var estimates: [SavedEstimate] = [] {
        didSet {
            save()
        }
    }
    
    private let storageKey = "saved_estimates"
    
    init() {
        load()
    }
    
    func saveEstimate(_ estimate: Estimate, for client: Client, totalPrice: Double, status: EstimateStatus = .sent) {
        let savedEstimate = SavedEstimate(
            estimate: estimate,
            client: client,
            totalPrice: totalPrice,
            status: status,
            dateSent: status == .sent ? Date() : nil,
            dateResponded: nil,
            customerNotes: nil,
            selectedItemIds: nil
        )
        estimates.append(savedEstimate)
    }
    
    func updateStatus(estimateId: UUID, status: EstimateStatus, selectedItemIds: Set<UUID>? = nil, notes: String? = nil) {
        guard let index = estimates.firstIndex(where: { $0.id == estimateId }) else { return }
        
        estimates[index].status = status
        estimates[index].dateResponded = Date()
        estimates[index].selectedItemIds = selectedItemIds
        
        if let notes = notes {
            estimates[index].customerNotes = notes
        }
    }
    
    func getEstimate(id: UUID) -> SavedEstimate? {
        estimates.first { $0.id == id }
    }
    
    func deleteEstimate(id: UUID) {
        estimates.removeAll { $0.id == id }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(estimates) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([SavedEstimate].self, from: data) {
            estimates = decoded
        }
    }
}
