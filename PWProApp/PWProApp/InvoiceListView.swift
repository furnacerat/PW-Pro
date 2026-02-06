import SwiftUI

struct InvoiceListView: View {
    @ObservedObject var invoiceManager = InvoiceManager.shared
    @State private var searchText = ""
    @State private var selectedStatus: InvoiceStatus?
    @State private var invoiceToDelete: Invoice?
    @State private var showingDeleteConfirmation = false

    
    var filteredInvoices: [Invoice] {
        invoiceManager.invoices.filter { invoice in
            let matchesSearch = searchText.isEmpty || 
                                invoice.clientName.localizedCaseInsensitiveContains(searchText) || 
                                invoice.invoiceNumber.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = selectedStatus == nil || invoice.status == selectedStatus
            return matchesSearch && matchesStatus
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Bar
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.slate500)
                    TextField("Search invoices...", text: $searchText)
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
                        
                        ForEach(InvoiceStatus.allCases, id: \.self) { status in
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
                if invoiceManager.isLoading {
                    // Skeleton loading state
                    VStack(spacing: 16) {
                        ForEach(0..<5, id: \.self) { _ in
                            SkeletonListItem()
                        }
                    }
                    .padding()
                } else if filteredInvoices.isEmpty {
                    PremiumEmptyState(
                        title: "No Invoices Found",
                        description: searchText.isEmpty ? "Create your first professional invoice to get paid." : "No invoices match your search.",
                        icon: "doc.text.fill",
                        actionTitle: searchText.isEmpty ? "Create New Invoice" : nil
                    ) {
                        // In real app, trigger new invoice flow
                    }
                    .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredInvoices) { invoice in
                            NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                                InvoiceSummaryRow(invoice: invoice)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    invoiceToDelete = invoice
                                    showingDeleteConfirmation = true
                                    HapticManager.warning()
                                } label: {
                                    Label("Delete Invoice", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Theme.slate900)
        .navigationTitle("Invoices")
        .task {
            if invoiceManager.invoices.isEmpty {
                await invoiceManager.fetchInvoices()
            }
        }
        .withErrorHandling(error: $invoiceManager.error)
        .alert("Delete Invoice?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                invoiceToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let invoice = invoiceToDelete {
                    invoiceManager.deleteInvoice(invoice)
                    invoiceToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this invoice? This action cannot be undone.")
        }
    }
}

struct InvoiceSummaryRow: View {
    let invoice: Invoice
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invoice.invoiceNumber)
                        .font(.caption.bold())
                        .foregroundColor(Theme.sky500)
                    Text(invoice.clientName)
                        .font(Theme.bodyFont)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(invoice.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(Theme.slate500)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text(String(format: "$%.2f", invoice.total))
                        .font(Theme.labelFont)
                        .foregroundColor(.white)
                    
                    Text(invoice.status.rawValue)
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(invoice.status.color.opacity(0.1))
                        .foregroundColor(invoice.status.color)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(invoice.status.color.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
    }
}
