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
    @Published var estimates: [SavedEstimate] = []
    @Published var isLoading = false
    @Published var error: String?
    
    static let shared = EstimateManager()
    private let supabase = SupabaseManager.shared
    private let estimateService: EstimateService
    
    private init() {
        self.estimateService = EstimateService(client: SupabaseManager.shared.client)
    }
    
    func fetchEstimates() async {
        isLoading = true
        error = nil
        
        do {
            let estimateDataList = try await estimateService.fetchEstimates()
            
            self.estimates = estimateDataList.map { data in
                // Map EstimateItemData -> EstimateItem
                let items = data.items.map { itemData in
                    EstimateItem(
                        description: itemData.description,
                        squareFootage: data.squareFootage ?? 2000, // Approximate fallback if not per item
                        quantity: itemData.quantity,
                        unitPrice: itemData.rate,
                        totalPrice: itemData.total
                    )
                }
                
                // Reconstruct Estimate object
                let estimate = Estimate(
                    items: items,
                    laborHours: 0, // Not persisted separately in EstimateData
                    hourlyRate: 100, // Default
                    pricingModel: .perSquareFoot, // Default or infer
                    pricePerSqFt: 0.15 // Default
                )
                
                return SavedEstimate(
                    id: data.id,
                    estimate: estimate,
                    client: Client(id: data.clientId ?? UUID(), name: data.clientName, email: "", phone: "", address: "", status: .regular, tags: [], jobHistory: [], interactions: []),
                    totalPrice: data.totalPrice,
                    status: EstimateStatus(rawValue: data.status) ?? .sent,
                    dateSent: data.createdAt,
                    dateResponded: data.updatedAt, // Using updatedAt as proxy
                    customerNotes: nil,
                    selectedItemIds: nil
                )
            }
        } catch {
            print("Error fetching estimates: \(error)")
            self.error = "Failed to load estimates."
        }
        
        isLoading = false
    }
    
    func saveEstimate(_ estimate: Estimate, for client: Client, totalPrice: Double, status: EstimateStatus = .sent) {
        Task {
            await createEstimate(estimate: estimate, for: client, totalPrice: totalPrice, status: status)
        }
    }
    
    func createEstimate(estimate: Estimate, for client: Client, totalPrice: Double, status: EstimateStatus) async {
        isLoading = true
        
        let newId = UUID()
        
        // 1. Map to Supabase Data
        let itemsData = estimate.items.map { item in
            EstimateItemData(
                description: item.description,
                quantity: item.quantity,
                rate: item.unitPrice,
                total: item.totalPrice
            )
        }
        
        let estimateData = EstimateData(
            id: newId,
            userId: supabase.currentUser?.id,
            clientId: client.id,
            clientName: client.name,
            jobName: "Estimate for \(client.name)",
            totalPrice: totalPrice,
            squareFootage: estimate.items.reduce(0) { $0 + $1.squareFootage },
            surfaceType: nil,
            items: itemsData,
            status: status.rawValue,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // 2. Optimistic Update
        let savedEstimate = SavedEstimate(
            id: newId,
            estimate: estimate,
            client: client,
            totalPrice: totalPrice,
            status: status,
            dateSent: Date(),
            dateResponded: nil,
            customerNotes: nil,
            selectedItemIds: nil
        )
        self.estimates.append(savedEstimate)
        
        // 3. Persist
        do {
            try await estimateService.insertEstimate(estimateData)
        } catch {
            print("Error saving estimate: \(error)")
            self.error = "Failed to save estimate to cloud."
        }
        
        isLoading = false
    }
    
    func updateStatus(estimateId: UUID, status: EstimateStatus, selectedItemIds: Set<UUID>? = nil, notes: String? = nil) {
        Task {
            guard let index = estimates.firstIndex(where: { $0.id == estimateId }) else { return }
            
            // Optimistic
            estimates[index].status = status
            if let notes = notes { estimates[index].customerNotes = notes }
            
            // Persist
            do {
                let savedEstimate = estimates[index]
                
                // Map items
                let itemsData = savedEstimate.estimate.items.map { item in
                    EstimateItemData(
                        description: item.description,
                        quantity: item.quantity,
                        rate: item.unitPrice,
                        total: item.totalPrice
                    )
                }
                
                let estimateData = EstimateData(
                    id: savedEstimate.id,
                    userId: supabase.currentUser?.id,
                    clientId: savedEstimate.client.id,
                    clientName: savedEstimate.client.name,
                    jobName: "Estimate for \(savedEstimate.client.name)",
                    totalPrice: savedEstimate.totalPrice,
                    squareFootage: savedEstimate.estimate.items.reduce(0) { $0 + $1.squareFootage },
                    surfaceType: nil,
                    items: itemsData,
                    status: status.rawValue,
                    createdAt: savedEstimate.dateSent,
                    updatedAt: Date()
                )
                
                try await estimateService.updateEstimate(estimateData)
            } catch {
                print("Error updating status: \(error)")
                self.error = "Failed to update status in cloud"
            }
        }
    }
    
    func getEstimate(id: UUID) -> SavedEstimate? {
        estimates.first { $0.id == id }
    }
    
    func deleteEstimate(id: UUID) {
        Task {
             estimates.removeAll { $0.id == id }
             try? await estimateService.deleteEstimate(id: id)
        }
    }
}
