import SwiftUI

struct EstimateDetailView: View {
    let estimate: SavedEstimate
    @ObservedObject private var estimateManager = EstimateManager.shared
    @ObservedObject private var invoiceManager = InvoiceManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedStatus: EstimateStatus
    @State private var customerNotes: String = ""
    @State private var selectedItems: Set<UUID>
    @State private var showingInvoiceSuccess = false
    @State private var showingBookingSheet = false
    
    init(estimate: SavedEstimate) {
        self.estimate = estimate
        _selectedStatus = State(initialValue: estimate.status)
        _customerNotes = State(initialValue: estimate.customerNotes ?? "")
        _selectedItems = State(initialValue: estimate.selectedItemIds ?? Set(estimate.estimate.items.map { $0.id }))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Status Badge
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: estimate.status.icon)
                        Text(estimate.status.rawValue.uppercased())
                            .font(.caption.bold())
                    }
                    .foregroundColor(estimate.status.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(estimate.status.color.opacity(0.1))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(estimate.status.color.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Client Info
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CLIENT DETAILS")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(estimate.client.name)
                                    .font(.title3)
                                    .foregroundColor(.white)
                                Text(estimate.client.email)
                                    .font(.body)
                                    .foregroundColor(Theme.slate400)
                            }
                            Spacer()
                        }
                        
                        Divider().background(Theme.slate700)
                        
                        Text(estimate.client.address)
                            .font(.body)
                            .foregroundColor(Theme.slate300)
                    }
                    .padding()
                }
                
                // Services List
                VStack(alignment: .leading, spacing: 12) {
                    Text("SERVICES INCLUDED")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate500)
                    
                    GlassCard {
                        VStack(spacing: 0) {
                            ForEach(estimate.estimate.items) { item in
                                VStack(spacing: 12) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.displayName)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text("$\(String(format: "%.2f", item.price))")
                                                .font(.subheadline)
                                                .foregroundColor(Theme.emerald500)
                                        }
                                        Spacer()
                                        
                                        if selectedStatus == .partial {
                                            Toggle("", isOn: Binding(
                                                get: { selectedItems.contains(item.id) },
                                                set: { isSelected in
                                                    if isSelected {
                                                        selectedItems.insert(item.id)
                                                    } else {
                                                        selectedItems.remove(item.id)
                                                    }
                                                }
                                            ))
                                            .labelsHidden()
                                            .tint(Theme.emerald500)
                                        }
                                    }
                                }
                                .padding()
                                
                                if item.id != estimate.estimate.items.last?.id {
                                    Divider().background(Theme.slate700)
                                }
                            }
                            
                            Divider().background(Theme.slate700)
                            
                            HStack {
                                Text("ESTIMATED TOTAL")
                                    .font(.headline)
                                    .foregroundColor(Theme.slate400)
                                Spacer()
                                Text("$\(String(format: "%.2f", estimate.totalPrice))")
                                    .font(.title2.bold())
                                    .foregroundColor(Theme.emerald500)
                            }
                            .padding()
                            .background(Theme.emerald500.opacity(0.05))
                        }
                    }
                }
                
                // Status Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("ACTIONS")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate500)
                        
                    if estimate.status == .approved || estimate.status == .partial {
                        VStack(spacing: 12) {
                            Button {
                                showingBookingSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "calendar.badge.plus")
                                    Text("Schedule Job")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.sky500)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            
                            Button {
                                createInvoiceFromEstimate()
                            } label: {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                    Text("Create Invoice")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.slate800)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            Text("Update Status to proceed")
                                .font(.caption)
                                .foregroundColor(Theme.slate500)
                                
                            HStack(spacing: 12) {
                                Button {
                                    updateStatus(to: .approved)
                                } label: {
                                    Text("Approve")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Theme.emerald500)
                                        .cornerRadius(12)
                                }
                                
                                Button {
                                    updateStatus(to: .rejected)
                                } label: {
                                    Text("Reject")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Theme.red500)
                                        .cornerRadius(12)
                                }
                            }
                            
                            Button {
                                selectedStatus = .partial
                            } label: {
                                Text("Partial Approval")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.sky500)
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                
                // Notes section
                 VStack(alignment: .leading, spacing: 8) {
                    Text("INTERNAL NOTES")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate500)
                    
                    GlassCard {
                        TextEditor(text: $customerNotes)
                            .frame(height: 100)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .foregroundColor(.white)
                            .font(.body)
                            .padding(4)
                    }
                }
            }
            .padding()
        }
        .background(Theme.slate900)
        .navigationTitle("Estimate Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
            }
        }
        .sheet(isPresented: $showingBookingSheet) {
            JobBookingView(invoice: Invoice(
                id: UUID(),
                estimateID: estimate.id,
                clientName: estimate.client.name,
                clientEmail: estimate.client.email,
                clientAddress: estimate.client.address,
                date: Date(),
                status: .draft,
                items: estimate.estimate.items,
                total: estimate.totalPrice,
                paymentLink: ""
            ))
        }
        .alert("Invoice Created", isPresented: $showingInvoiceSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Invoice has been successfully created.")
        }
    }
    
    private func updateStatus(to status: EstimateStatus) {
        selectedStatus = status
        saveChanges()
    }
    
    private func saveChanges() {
        estimateManager.updateStatus(
            estimateId: estimate.id,
            status: selectedStatus,
            selectedItemIds: selectedStatus == .partial ? selectedItems : nil,
            notes: customerNotes.isEmpty ? nil : customerNotes
        )
        HapticManager.success()
        dismiss()
    }
    
    private func createInvoiceFromEstimate() {
        // Logic same as before
        var estimateToUse = estimate.estimate
        if selectedStatus == .partial {
            estimateToUse.items = estimate.estimate.items.filter { selectedItems.contains($0.id) }
        }
        
        let totalPrice = estimateToUse.items.reduce(0.0) { total, item in
            switch estimate.estimate.pricingModel {
            case .perSquareFoot:
                return total + (item.squareFootage * estimate.estimate.pricePerSqFt)
            case .costPlus:
                let totalSqFt = estimateToUse.items.reduce(0) { $0 + $1.squareFootage }
                let proportion = totalSqFt > 0 ? item.squareFootage / totalSqFt : 0
                return total + (estimate.totalPrice * proportion)
            }
        }
        
        _ = invoiceManager.createInvoice(from: estimateToUse, for: estimate.client, totalPrice: totalPrice)
        saveChanges()
        showingInvoiceSuccess = true
    }
}
