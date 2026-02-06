import SwiftUI

struct InvoiceDetailView: View {
    let invoice: Invoice
    @State private var showingShareSheet = false
    @State private var showingBookingSheet = false
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
                
                // Payment Section
                if !invoice.paymentLink.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PAYMENT METHOD")
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
                
                // Share Actions
                VStack(spacing: 12) {
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
