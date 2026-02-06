import SwiftUI

struct InvoiceDetailView: View {
    let invoice: Invoice
    @ObservedObject private var invoiceManager = InvoiceManager.shared
    @State private var showingShareSheet = false
    @State private var showingBookingSheet = false
    @State private var showingPaymentSheet = false
    @State private var shareContent: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status Header
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(invoice.invoiceNumber)
                                .font(.caption.bold())
                                .foregroundColor(Theme.sky500)
                            Text(invoice.status.rawValue.uppercased())
                                .font(Theme.headingFont)
                                .foregroundColor(invoice.status.color)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("TOTAL DUE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.slate500)
                            Text(String(format: "$%.2f", invoice.total))
                                .font(.title3.bold())
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Invoice Body
                GlassCard {
                    VStack(alignment: .leading, spacing: 20) {
                        // Branding
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(InvoiceManager.shared.businessSettings.businessName)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(InvoiceManager.shared.businessSettings.businessAddress)
                                    .font(.caption2)
                                    .foregroundColor(Theme.slate500)
                                Text(InvoiceManager.shared.businessSettings.businessPhone)
                                    .font(.system(size: 8))
                                    .foregroundColor(Theme.slate600)
                            }
                            Spacer()
                            
                            #if os(macOS)
                            if let data = InvoiceManager.shared.businessSettings.logoData, let nsImage = NSImage(data: data) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                            } else {
                                AppLogoView(size: 40)
                            }
                            #else
                            if let data = InvoiceManager.shared.businessSettings.logoData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                            } else {
                                AppLogoView(size: 40)
                            }
                            #endif
                        }
                        
                        Divider().background(Theme.slate700)
                        
                        // Bill To
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BILL TO")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.slate500)
                            Text(invoice.clientName)
                                .font(Theme.bodyFont)
                                .foregroundColor(.white)
                            Text(invoice.clientAddress)
                                .font(.caption2)
                                .foregroundColor(Theme.slate500)
                        }
                        
                        // Items Table
                        VStack(spacing: 12) {
                            HStack {
                                Text("DESCRIPTION")
                                    .font(.system(size: 8, weight: .bold))
                                Spacer()
                                Text("AMOUNT")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .foregroundColor(Theme.slate500)
                            
                            ForEach(invoice.items) { item in
                                HStack {
                                    Text(item.description)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(String(format: "$%.2f", item.amount))
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        Divider().background(Theme.slate700)
                        
                        // Calculations
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("TERMS")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(Theme.slate500)
                                Text(InvoiceManager.shared.businessSettings.customTerms)
                                    .font(.system(size: 8))
                                    .foregroundColor(Theme.slate600)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .trailing, spacing: 8) {
                                HStack {
                                    Text("Subtotal")
                                    Text(String(format: "$%.2f", invoice.total))
                                }
                                .font(.caption)
                                .foregroundColor(Theme.slate400)
                                
                                HStack {
                                    Text("Total")
                                    Text(String(format: "$%.2f", invoice.total))
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                }
                
                // Payment Details (for paid invoices)
                if invoice.status == .paid, let method = invoice.paymentMethod {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PAYMENT DETAILS")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                        
                        GlassCard {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: method.icon)
                                        .foregroundColor(Theme.emerald500)
                                    Text("Payment Method")
                                        .foregroundColor(Theme.slate400)
                                    Spacer()
                                    Text(method.rawValue)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .font(.caption)
                                
                                if let checkNumber = invoice.checkNumber {
                                    Divider().background(Theme.slate700)
                                    HStack {
                                        Image(systemName: "number")
                                            .foregroundColor(Theme.sky500)
                                        Text("Check Number")
                                            .foregroundColor(Theme.slate400)
                                        Spacer()
                                        Text(checkNumber)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                    .font(.caption)
                                }
                                
                                if let paidDate = invoice.paidDate {
                                    Divider().background(Theme.slate700)
                                    HStack {
                                        Image(systemName: "calendar.badge.checkmark")
                                            .foregroundColor(Theme.emerald500)
                                        Text("Paid On")
                                            .foregroundColor(Theme.slate400)
                                        Spacer()
                                        Text(paidDate.formatted(date: .abbreviated, time: .omitted))
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                    .font(.caption)
                                }
                            }
                        }
                    }
                }
                
                // Online Payment Section (for unpaid invoices with payment link)
                if invoice.status != .paid && !invoice.paymentLink.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ONLINE PAYMENT")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                        
                        GlassCard {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(Theme.sky500)
                                VStack(alignment: .leading) {
                                    Text("Online Payment Available")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                    Text("Secure checkout via \(InvoiceManager.shared.businessSettings.paymentProvider.rawValue)")
                                        .font(.system(size: 8))
                                        .foregroundColor(Theme.slate500)
                                }
                                Spacer()
                                Link(destination: URL(string: invoice.paymentLink)!) {
                                    Text("Pay Now")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Theme.emerald500)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                
                // Actions
                VStack(spacing: 12) {
                    // Mark as Paid button (for unpaid invoices)
                    if invoice.status != .paid {
                        NeonButton(title: "Mark as Paid", color: Theme.emerald500, icon: "checkmark.circle.fill") {
                            showingPaymentSheet = true
                        }
                    }
                    
                    // Generate Receipt button (for paid invoices)
                    if invoice.status == .paid {
                        NavigationLink(destination: ReceiptView(invoice: invoice)) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("Generate Receipt")
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
                    }
                    
                    NeonButton(title: "Text Invoice", color: Theme.sky500, icon: "message.fill") {
                        prepareAndShare(via: .text)
                    }
                    
                    NeonButton(title: "Email Invoice", color: Theme.sky500, icon: "envelope.fill") {
                        prepareAndShare(via: .email)
                    }
                    
                    if invoice.status != .paid {
                        NeonButton(title: "Book Job", color: Theme.emerald500, icon: "calendar.badge.plus") {
                            showingBookingSheet = true
                        }
                    }
                }
                .padding(.top, 10)
            }
            .padding()
        }
        .background(Theme.slate900)
        .navigationTitle("Invoice Details")
        #if os(iOS)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [shareContent])
        }
        #endif
        .sheet(isPresented: $showingBookingSheet) {
            JobBookingView(invoice: invoice)
        }
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentMethodSheet(invoice: invoice, onComplete: {
                showingPaymentSheet = false
            })
        }
    }
    
    enum ShareType { case text, email }
    
    private func prepareAndShare(via type: ShareType) {
        let business = BusinessSettings.shared.businessName
        let total = String(format: "$%.2f", invoice.total)
        let link = invoice.paymentLink.isEmpty ? "" : "\n\nPay online here: \(invoice.paymentLink)"
        
        let content: String
        if type == .text {
            content = "Hi \(invoice.clientName), here is your invoice from \(business). Total: \(total).\(link)"
        } else {
            content = """
            Invoice \(invoice.invoiceNumber)
            From: \(business)
            Amount: \(total)
            
            Thank you for your business!\(link)
            """
        }
        
        #if os(macOS)
        let picker = NSSharingServicePicker(items: [content])
        picker.show(relativeTo: .zero, of: NSApp.keyWindow?.contentView ?? NSView(), preferredEdge: .minY)
        #else
        shareContent = content
        showingShareSheet = true
        #endif
    }
}

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - Payment Method Selection Sheet

struct PaymentMethodSheet: View {
    let invoice: Invoice
    let onComplete: () -> Void
    
    @ObservedObject private var invoiceManager = InvoiceManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedMethod: PaymentMethod?
    @State private var checkNumber: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.emerald500)
                        
                        Text("Mark Invoice as Paid")
                            .font(Theme.headingFont)
                            .foregroundColor(.white)
                        
                        Text("Select how payment was received")
                            .font(.caption)
                            .foregroundColor(Theme.slate400)
                    }
                    .padding(.top, 20)
                    
                    // Payment Method Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PAYMENT METHOD")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(PaymentMethod.allCases, id: \.self) { method in
                                Button {
                                    selectedMethod = method
                                    HapticManager.selection()
                                } label: {
                                    VStack(spacing: 12) {
                                        Image(systemName: method.icon)
                                            .font(.system(size: 32))
                                            .foregroundColor(selectedMethod == method ? Theme.emerald500 : Theme.slate500)
                                        
                                        Text(method.rawValue)
                                            .font(.caption.bold())
                                            .foregroundColor(selectedMethod == method ? .white : Theme.slate400)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(selectedMethod == method ? Theme.emerald500.opacity(0.1) : Theme.slate800)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedMethod == method ? Theme.emerald500 : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Check Number Input (only shown when Check is selected)
                    if selectedMethod == .check {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CHECK NUMBER (OPTIONAL)")
                                .font(Theme.labelFont)
                                .foregroundColor(Theme.slate500)
                            
                            TextField("Enter check number", text: $checkNumber)
                                .padding()
                                .background(Theme.slate800)
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .keyboardType(.numberPad)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Invoice Summary
                    GlassCard {
                        VStack(spacing: 12) {
                            HStack {
                                Text("INVOICE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.slate500)
                                Spacer()
                                Text(invoice.invoiceNumber)
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.sky500)
                            }
                            
                            Divider().background(Theme.slate700)
                            
                            HStack {
                                Text("Client")
                                    .foregroundColor(Theme.slate400)
                                Spacer()
                                Text(invoice.clientName)
                                    .foregroundColor(.white)
                            }
                            .font(.caption)
                            
                            HStack {
                                Text("Amount")
                                    .foregroundColor(Theme.slate400)
                                Spacer()
                                Text(String(format: "$%.2f", invoice.total))
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.emerald500)
                            }
                            .font(.caption)
                        }
                    }
                    
                    // Confirm Button
                    Button {
                        if let method = selectedMethod {
                            invoiceManager.markAsPaid(
                                invoiceId: invoice.id,
                                method: method,
                                checkNumber: checkNumber.isEmpty ? nil : checkNumber
                            )
                            HapticManager.success()
                            onComplete()
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Confirm Payment")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedMethod != nil ? Theme.emerald500 : Theme.slate700)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: selectedMethod != nil ? Theme.emerald500.opacity(0.3) : Color.clear, radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedMethod == nil)
                }
                .padding()
            }
            .background(Theme.slate900)
            .navigationTitle("Record Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
