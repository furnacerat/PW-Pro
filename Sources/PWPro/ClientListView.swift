import SwiftUI

struct ClientListView: View {
    @Binding var clients: [Client]
    @State private var searchText = ""
    @State private var selectedStatus: ClientStatus?
    
    var filteredClients: [Client] {
        clients.filter { client in
            let matchesSearch = searchText.isEmpty || 
                                client.name.localizedCaseInsensitiveContains(searchText) || 
                                client.address.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = selectedStatus == nil || client.status == selectedStatus
            return matchesSearch && matchesStatus
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.slate500)
                    TextField("Search clients...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(Theme.slate800)
                .cornerRadius(12)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterTag(title: "All", isSelected: selectedStatus == nil) {
                            selectedStatus = nil
                        }
                        
                        ForEach(ClientStatus.allCases, id: \.self) { status in
                            FilterTag(title: status.rawValue, isSelected: selectedStatus == status) {
                                selectedStatus = status
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Theme.slate900)
            
            // List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredClients) { client in
                        NavigationLink(destination: ClientDetailView(client: binding(for: client))) {
                            ClientRow(client: client)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .background(Theme.slate900)
        .navigationTitle("Clients")
    }
    
    private func binding(for client: Client) -> Binding<Client> {
        guard let index = clients.firstIndex(where: { $0.id == client.id }) else {
            fatalError("Client not found")
        }
        return $clients[index]
    }
}

struct ClientRow: View {
    let client: Client
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                // Initial Circle
                Text(String(client.name.prefix(1)))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(client.status.color.opacity(0.3))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(client.status.color.opacity(0.5), lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.name)
                        .font(Theme.bodyFont)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(client.address)
                        .font(.caption)
                        .foregroundColor(Theme.slate400)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(Int(client.totalLifetimeValue))")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.sky500)
                    Text(client.status.rawValue)
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(client.status.color.opacity(0.1))
                        .foregroundColor(client.status.color)
                        .cornerRadius(4)
                }
            }
        }
    }
}

struct FilterTag: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Theme.sky500 : Theme.slate800)
                .foregroundColor(isSelected ? .white : Theme.slate400)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Theme.slate700, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
