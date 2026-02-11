import Foundation
import SwiftUI

@MainActor
class ClientManager: ObservableObject {
    @Published var clients: [Client] = []
    @Published var isLoading = false
    @Published var error: String?
    
    static let shared = ClientManager()
    private let clientService: ClientService
    private let supabase = SupabaseManager.shared
    
    private init() {
        self.clientService = ClientService(client: SupabaseManager.shared.client)
    }
    
    func fetchClients() async {
        isLoading = true
        error = nil
        
        do {
            // Use ClientService
            let clientData = try await clientService.fetchClients()
            
            // Convert Supabase data to app Client model
            clients = clientData.map { data in
                Client(
                    id: data.id,
                    name: data.name,
                    email: data.email ?? "",
                    phone: data.phone ?? "",
                    address: data.address ?? "",
                    status: .regular,
                    tags: [],
                    jobHistory: [],
                    interactions: []
                )
            }
            
            // If no clients exist, add mock data for demo
            if clients.isEmpty {
                for mockClient in Client.mockClients {
                    await addClient(mockClient)
                }
            }
        } catch {
            self.error = error.localizedDescription
            print("Failed to fetch clients: \(error)")
            // Fallback to mock data on error
            clients = Client.mockClients
        }
        
        isLoading = false
    }
    
    func addClient(_ client: Client) async {
        // Optimistic UI Update:
        // We append the new client to the local array immediately so the user sees it instantly.
        // This makes the app feel incredibly fast. If the backend call fails later, we fallback/revert.
        clients.append(client)
        
        do {
            let clientData = ClientData(
                id: client.id,
                userId: supabase.currentUser?.id,
                name: client.name,
                email: client.email.isEmpty ? nil : client.email,
                phone: client.phone.isEmpty ? nil : client.phone,
                address: client.address.isEmpty ? nil : client.address,
                rating: Int(client.rating),
                totalSpent: client.totalSpent,
                lifetimeJobs: client.lifetimeJobs,
                createdAt: nil,
                updatedAt: nil
            )
            
            try await clientService.insertClient(clientData)
        } catch {
            // Rollback on error
            clients.removeAll { $0.id == client.id }
            self.error = "Failed to add client: \(error.localizedDescription)"
            print("Failed to add client: \(error)")
        }
    }
    
    func updateClient(_ client: Client) async {
        // Optimistic update
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index] = client
        }
        
        do {
            let clientData = ClientData(
                id: client.id,
                userId: supabase.currentUser?.id,
                name: client.name,
                email: client.email.isEmpty ? nil : client.email,
                phone: client.phone.isEmpty ? nil : client.phone,
                address: client.address.isEmpty ? nil : client.address,
                rating: Int(client.rating),
                totalSpent: client.totalSpent,
                lifetimeJobs: client.lifetimeJobs,
                createdAt: nil,
                updatedAt: nil
            )
            
            try await clientService.updateClient(clientData)
        } catch {
            self.error = "Failed to update client: \(error.localizedDescription)"
            print("Failed to update client: \(error)")
            // Refetch to revert
            await fetchClients()
        }
    }
    
    func deleteClient(_ client: Client) async {
        // Optimistic Delete:
        // Remove from UI immediately for responsiveness.
        // If the Supabase request fails, we will re-fetch the list to restore the correct state.
        clients.removeAll { $0.id == client.id }
        
        do {
            try await clientService.deleteClient(id: client.id)
        } catch {
            self.error = "Failed to delete client: \(error.localizedDescription)"
            print("Failed to delete client: \(error)")
            // Refetch to revert
            await fetchClients()
        }
    }
}
