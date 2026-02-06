import SwiftUI

struct EstimatesListView: View {
    @ObservedObject private var estimateManager = EstimateManager.shared
    @ObservedObject private var invoiceManager = InvoiceManager.shared
    @State private var selectedEstimate: SavedEstimate?
    @State private var showingStatusUpdate = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if estimateManager.estimates.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.slate600)
                        
                        Text("No Estimates Yet")
                            .font(Theme.headingFont)
                            .foregroundColor(.white)
                        
                        Text("Estimates you send to customers will appear here")
                            .font(.caption)
                            .foregroundColor(Theme.slate500)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    ForEach(estimateManager.estimates.sorted(by: { $0.displayDate > $1.displayDate })) { savedEstimate in
                        EstimateCard(estimate: savedEstimate) {
                            selectedEstimate = savedEstimate
                            showingStatusUpdate = true
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.slate900)
        .navigationTitle("Sent Estimates")
        .sheet(isPresented: $showingStatusUpdate) {
            if let estimate = selectedEstimate {
                EstimateStatusSheet(estimate: estimate)
            }
        }
    }
}

struct EstimateCard: View {
    let estimate: SavedEstimate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(estimate.client.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if let dateSent = estimate.dateSent {
                                Text("Sent \(dateSent.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2)
                                    .foregroundColor(Theme.slate500)
                            }
                        }
                        
                        Spacer()
                        
                        // Status badge
                        HStack(spacing: 4) {
                            Image(systemName: estimate.status.icon)
                            Text(estimate.status.rawValue)
                                .font(.caption.bold())
                        }
                        .foregroundColor(estimate.status.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(estimate.status.color.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Divider().background(Theme.slate700)
                    
                    // Items summary
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SERVICES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.slate500)
                        
                        ForEach(estimate.estimate.items.prefix(3)) { item in
                            Text("• \(item.displayName)")
                                .font(.caption)
                                .foregroundColor(Theme.slate400)
                        }
                        
                        if estimate.estimate.items.count > 3 {
                            Text("+ \(estimate.estimate.items.count - 3) more")
                                .font(.caption)
                                .foregroundColor(Theme.slate500)
                        }
                    }
                    
                    Divider().background(Theme.slate700)
                    
                    // Total
                    HStack {
                        Text("TOTAL")
                            .font(.caption.bold())
                            .foregroundColor(Theme.slate500)
                        Spacer()
                        Text(String(format: "$%.2f", estimate.totalPrice))
                            .font(.title3.bold())
                            .foregroundColor(Theme.emerald500)
                    }
                    
                    // Customer notes (if any)
                    if let notes = estimate.customerNotes, !notes.isEmpty {
                        Divider().background(Theme.slate700)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NOTES")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.slate500)
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(Theme.slate400)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct EstimateStatusSheet: View {
    let estimate: SavedEstimate
    @ObservedObject private var estimateManager = EstimateManager.shared
    @ObservedObject private var invoiceManager = InvoiceManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedStatus: EstimateStatus
    @State private var customerNotes: String = ""
    @State private var selectedItems: Set<UUID>
    @State private var showingInvoiceSuccess = false
    
    init(estimate: SavedEstimate) {
        self.estimate = estimate
        _selectedStatus = State(initialValue: estimate.status)
        _customerNotes = State(initialValue: estimate.customerNotes ?? "")
        _selectedItems = State(initialValue: estimate.selectedItemIds ?? Set(estimate.estimate.items.map { $0.id }))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Estimate info
                    GlassCard {
                        VStack(spacing: 12) {
                            HStack {
                                Text("CLIENT")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.slate500)
                                Spacer()
                                Text(estimate.client.name)
                                    .foregroundColor(.white)
                            }
                            
                            Divider().background(Theme.slate700)
                            
                            HStack {
                                Text("TOTAL")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.slate500)
                                Spacer()
                                Text(String(format: "$%.2f", estimate.totalPrice))
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.emerald500)
                            }
                        }
                    }
                    
                    // Status selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("UPDATE STATUS")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                        
                        VStack(spacing: 8) {
                            ForEach([EstimateStatus.approved, .partial, .rejected], id: \.self) { status in
                                Button {
                                    selectedStatus = status
                                    HapticManager.selection()
                                } label: {
                                    HStack {
                                        Image(systemName: status.icon)
                                            .foregroundColor(selectedStatus == status ? status.color : Theme.slate500)
                                        
                                        Text(status.rawValue)
                                            .foregroundColor(selectedStatus == status ? .white : Theme.slate400)
                                        
                                        Spacer()
                                        
                                        if selectedStatus == status {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(status.color)
                                        }
                                    }
                                    .padding()
                                    .background(selectedStatus == status ? status.color.opacity(0.1) : Theme.slate800)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedStatus == status ? status.color : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Item selection (for partial approval)
                    if selectedStatus == .partial {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SELECT SERVICES")
                                .font(Theme.labelFont)
                                .foregroundColor(Theme.slate500)
                            
                            GlassCard {
                                VStack(spacing: 8) {
                                    ForEach(estimate.estimate.items) { item in
                                        Toggle(isOn: Binding(
                                            get: { selectedItems.contains(item.id) },
                                            set: { isSelected in
                                                if isSelected {
                                                    selectedItems.insert(item.id)
                                                } else {
                                                    selectedItems.remove(item.id)
                                                }
                                            }
                                        )) {
                                            Text(item.displayName)
                                                .foregroundColor(.white)
                                        }
                                        .tint(Theme.emerald500)
                                        
                                        if item.id != estimate.estimate.items.last?.id {
                                            Divider().background(Theme.slate700)
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Customer notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTES (OPTIONAL)")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                        
                        TextEditor(text: $customerNotes)
                            .frame(height: 100)
                            .padding(8)
                            .background(Theme.slate800)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        if selectedStatus == .approved || selectedStatus == .partial {
                            Button {
                                createInvoiceFromEstimate()
                            } label: {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                    Text("Update & Create Invoice")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.emerald500)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Theme.emerald500.opacity(0.3), radius: 10, y: 5)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                updateEstimateStatus()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Update Status")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.sky500)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Theme.sky500.opacity(0.3), radius: 10, y: 5)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .background(Theme.slate900)
            .navigationTitle("Update Estimate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Invoice Created!", isPresented: $showingInvoiceSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Invoice has been created successfully from this estimate.")
            }
        }
    }
    
    private func updateEstimateStatus() {
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
        // Create a modified estimate with only selected items if partial
        var estimateToUse = estimate.estimate
        if selectedStatus == .partial {
            estimateToUse.items = estimate.estimate.items.filter { selectedItems.contains($0.id) }
        }
        
        // Calculate total for selected items
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
        
        // Create invoice
        _ = invoiceManager.createInvoice(from: estimateToUse, for: estimate.client, totalPrice: totalPrice)
        
        // Update estimate status
        estimateManager.updateStatus(
            estimateId: estimate.id,
            status: selectedStatus,
            selectedItemIds: selectedStatus == .partial ? selectedItems : nil,
            notes: customerNotes.isEmpty ? nil : customerNotes
        )
        
        HapticManager.success()
        showingInvoiceSuccess = true
    }
}
