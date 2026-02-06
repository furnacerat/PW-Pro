import SwiftUI

struct ReceiptView: View {
    let invoice: Invoice
    @State private var showingShareSheet = false
    @State private var shareContent: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Receipt Header
                VStack(spacing: 8) {
                    Text("RECEIPT")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Theme.emerald500)
                    
                    Text(invoice.receiptNumber)
                        .font(.caption.bold())
                        .foregroundColor(Theme.slate500)
                    
                    if let paidDate = invoice.paidDate {
                        Text(paidDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(Theme.slate400)
                    }
                }
                .padding(.top, 20)
                
                // Business & Client Info
                GlassCard {
                    VStack(alignment: .leading, spacing: 20) {
                        // Business Info
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
                        
                        // Client Info
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PAID BY")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.slate500)
                            Text(invoice.clientName)
                                .font(Theme.bodyFont)
                                .foregroundColor(.white)
                            Text(invoice.clientAddress)
                                .font(.caption2)
                                .foregroundColor(Theme.slate500)
                        }
                    }
                    .padding()
                }
                
                // Payment Details
                GlassCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text("PAYMENT DETAILS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.slate500)
                            Spacer()
                        }
                        
                        if let method = invoice.paymentMethod {
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
                        }
                        
                        if let checkNumber = invoice.checkNumber {
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
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(Theme.sky500)
                                Text("Date Paid")
                                    .foregroundColor(Theme.slate400)
                                Spacer()
                                Text(paidDate.formatted(date: .abbreviated, time: .omitted))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .font(.caption)
                        }
                    }
                    .padding()
                }
                
                // Services Provided
                GlassCard {
                    VStack(spacing: 12) {
                        HStack {
                            Text("SERVICES PROVIDED")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.slate500)
                            Spacer()
                        }
                        
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
                            
                            if item.id != invoice.items.last?.id {
                                Divider().background(Theme.slate800)
                            }
                        }
                        
                        Divider().background(Theme.slate700)
                        
                        // Total
                        HStack {
                            Text("TOTAL PAID")
                                .font(.caption.bold())
                                .foregroundColor(Theme.slate400)
                            Spacer()
                            Text(String(format: "$%.2f", invoice.total))
                                .font(.title3.bold())
                                .foregroundColor(Theme.emerald500)
                        }
                    }
                    .padding()
                }
                
                // Thank You Message
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.emerald500)
                    
                    Text("Thank you for your business!")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("We appreciate your prompt payment.")
                        .font(.caption)
                        .foregroundColor(Theme.slate400)
                }
                .padding(.vertical, 20)
                
                // Share Actions
                VStack(spacing: 12) {
                    NeonButton(title: "Text Receipt", color: Theme.sky500, icon: "message.fill") {
                        prepareAndShare(via: .text)
                    }
                    
                    NeonButton(title: "Email Receipt", color: Theme.sky500, icon: "envelope.fill") {
                        prepareAndShare(via: .email)
                    }
                }
            }
            .padding()
        }
        .background(Theme.slate900)
        .navigationTitle("Receipt")
        #if os(iOS)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [shareContent])
        }
        #endif
    }
    
    enum ShareType { case text, email }
    
    private func prepareAndShare(via type: ShareType) {
        let business = InvoiceManager.shared.businessSettings.businessName
        let total = String(format: "$%.2f", invoice.total)
        let method = invoice.paymentMethod?.rawValue ?? "N/A"
        let date = invoice.paidDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A"
        
        let itemsList = invoice.items.map { "• \($0.description): $\(String(format: "%.2f", $0.amount))" }.joined(separator: "\n")
        
        let content: String
        if type == .text {
            content = """
            Receipt \(invoice.receiptNumber)
            From: \(business)
            
            Paid by: \(invoice.clientName)
            Amount: \(total)
            Payment Method: \(method)
            Date: \(date)
            
            Thank you for your business!
            """
        } else {
            var checkInfo = ""
            if let checkNum = invoice.checkNumber {
                checkInfo = "\nCheck #: \(checkNum)"
            }
            
            content = """
            RECEIPT
            \(invoice.receiptNumber)
            
            From: \(business)
            \(InvoiceManager.shared.businessSettings.businessAddress)
            \(InvoiceManager.shared.businessSettings.businessPhone)
            
            ---
            
            PAID BY:
            \(invoice.clientName)
            \(invoice.clientAddress)
            
            PAYMENT DETAILS:
            Payment Method: \(method)\(checkInfo)
            Date Paid: \(date)
            
            SERVICES PROVIDED:
            \(itemsList)
            
            TOTAL PAID: \(total)
            
            ---
            
            Thank you for your business!
            We appreciate your prompt payment.
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
