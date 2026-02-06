import Foundation
import SwiftUI

@MainActor
class ClientManager: ObservableObject {
    @Published var clients: [Client] = []
    
    private let filename = "clients.json"
    static let shared = ClientManager()
    
    private init() {
        load()
        if clients.isEmpty {
            self.clients = Client.mockClients
            save()
        }
    }
    
    func addClient(_ client: Client) {
        clients.append(client)
        save()
    }
    
    func updateClient(_ client: Client) {
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index] = client
            save()
        }
    }
    
    func save() {
        StorageManager.shared.save(clients, to: filename)
    }
    
    private func load() {
        if let loaded: [Client] = StorageManager.shared.load([Client].self, from: filename) {
            self.clients = loaded
        }
    }
}
