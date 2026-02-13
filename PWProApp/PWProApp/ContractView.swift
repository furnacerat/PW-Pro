import SwiftUI

struct ContractView: View {
    let invoice: Invoice
    @ObservedObject var invoiceManager = InvoiceManager.shared
    @State private var selectedDocuments: Set<UUID> = []
    
    // Auto-select defaults
    private func setupDefaults() {
        let defaults = invoiceManager.businessSettings.documents.filter { $0.isDefault }.map { $0.id }
        selectedDocuments = Set(defaults)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        #if os(macOS)
                        if let data = invoiceManager.businessSettings.logoData, let nsImage = NSImage(data: data) {
                             Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                        } else {
                            Text(invoiceManager.businessSettings.businessName)
                                .font(.title2.bold())
                        }
                        #else
                        if let data = invoiceManager.businessSettings.logoData, let uiImage = UIImage(data: data) {
                             Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                        } else {
                            Text(invoiceManager.businessSettings.businessName)
                                .font(.title2.bold())
                        }
                        #endif
                        
                        Text(invoiceManager.businessSettings.businessAddress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("CONTRACT")
                            .font(.largeTitle.bold())
                            .foregroundColor(.primary)
                        Text(invoice.date, style: .date)
                            .foregroundColor(.secondary)
                        Text(invoice.invoiceNumber)
                            .font(.caption.monospaced())
                    }
                }
                
                Divider()
                
                // Client Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("CLIENT")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text(invoice.clientName)
                        .font(.headline)
                    Text(invoice.clientAddress)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Scope of Work (Invoice Items)
                VStack(alignment: .leading, spacing: 12) {
                    Text("SCOPE OF WORK")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    ForEach(invoice.items) { item in
                        HStack {
                            Text(item.description)
                            Spacer()
                            Text(String(format: "$%.2f", item.amount))
                        }
                        .font(.body)
                    }
                    
                    Divider()
                    
                    HStack {
                        Spacer()
                        Text("Total: \(String(format: "$%.2f", invoice.total))")
                            .font(.headline)
                    }
                }
                
                // Standard Terms
                VStack(alignment: .leading, spacing: 8) {
                    Text("TERMS & CONDITIONS")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text(invoiceManager.businessSettings.customTerms)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Appended Documents
                if !selectedDocuments.isEmpty {
                    ForEach(invoiceManager.businessSettings.documents.filter { selectedDocuments.contains($0.id) }) { doc in
                        Divider()
                        VStack(alignment: .leading, spacing: 12) {
                            Text(doc.title.uppercased())
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            Text(doc.content)
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer(minLength: 40)
                
                // Signatures
                HStack(spacing: 40) {
                    VStack {
                        Rectangle().frame(height: 1).foregroundColor(.black)
                        Text("Client Signature").font(.caption)
                    }
                    VStack {
                        Rectangle().frame(height: 1).foregroundColor(.black)
                        Text("Date").font(.caption)
                    }
                }
                .padding(.top, 40)
            }
            .padding(40) // Print-like padding
            .background(Color.white)
            .foregroundColor(.black) // Force black text for print style
        }
        .onAppear { setupDefaults() }
        .navigationTitle("Contract Preview")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                // Share Sheet Logic here
                ShareContractButton(invoice: invoice, selectedDocs: selectedDocuments)
            }
        }
    }
}

// Wrapper to share rendered content
struct ShareContractButton: View {
    let invoice: Invoice
    let selectedDocs: Set<UUID>
    
    var body: some View {
        ShareLink(item: renderPDF(), preview: SharePreview("Contract \(invoice.invoiceNumber)")) {
            Label("Share PDF", systemImage: "square.and.arrow.up")
        }
    }
    
    @MainActor
    private func renderPDF() -> URL {
        let renderer = ImageRenderer(content: ContractPrintingView(invoice: invoice, selectedDocs: selectedDocs))
        let url = URL.documentsDirectory.appending(path: "Contract-\(invoice.invoiceNumber).pdf")
        
        renderer.render { size, context in
            var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }
        return url
    }
}

// Simplified view for PDF rendering (no scrolling, white bg)
struct ContractPrintingView: View {
    let invoice: Invoice
    let selectedDocs: Set<UUID>
    @ObservedObject var invoiceManager = InvoiceManager.shared
    
    var body: some View {
        VStack(spacing: 32) {
             // Header
             HStack(alignment: .top) {
                 VStack(alignment: .leading) {
                    #if os(macOS)
                    if let data = invoiceManager.businessSettings.logoData, let nsImage = NSImage(data: data) {
                         Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                    } else {
                        Text(invoiceManager.businessSettings.businessName)
                            .font(.title2.bold())
                    }
                    #else
                    if let data = invoiceManager.businessSettings.logoData, let uiImage = UIImage(data: data) {
                         Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                    } else {
                        Text(invoiceManager.businessSettings.businessName)
                            .font(.title2.bold())
                    }
                    #endif
                     
                     Text(invoiceManager.businessSettings.businessAddress)
                         .font(.caption)
                 }
                 Spacer()
                 VStack(alignment: .trailing) {
                     Text("CONTRACT")
                         .font(.largeTitle.bold())
                     Text(invoice.date, style: .date)
                     Text(invoice.invoiceNumber)
                         .font(.caption.monospaced())
                 }
             }
            
            Divider()
            
            // Client Info
            VStack(alignment: .leading, spacing: 8) {
                Text("CLIENT")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text(invoice.clientName)
                    .font(.headline)
                Text(invoice.clientAddress)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Scope
            VStack(alignment: .leading, spacing: 12) {
                Text("SCOPE OF WORK")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                ForEach(invoice.items) { item in
                    HStack {
                        Text(item.description)
                        Spacer()
                        Text(String(format: "$%.2f", item.amount))
                    }
                }
                Divider()
                HStack {
                    Spacer()
                    Text("Total: \(String(format: "$%.2f", invoice.total))")
                        .font(.headline)
                }
            }
            
            // Terms
            VStack(alignment: .leading, spacing: 8) {
                Text("TERMS & CONDITIONS")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text(invoiceManager.businessSettings.customTerms)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Appended Documents
            ForEach(invoiceManager.businessSettings.documents.filter { selectedDocs.contains($0.id) }) { doc in
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    Text(doc.title.uppercased())
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text(doc.content)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer(minLength: 60)
            
            HStack(spacing: 40) {
                VStack {
                    Rectangle().frame(height: 1).foregroundColor(.black)
                    Text("Client Signature").font(.caption)
                }
                VStack {
                    Rectangle().frame(height: 1).foregroundColor(.black)
                    Text("Date").font(.caption)
                }
            }
        }
        .padding(40)
        .frame(width: 612) // US Letter width approx
        .background(Color.white)
        .foregroundColor(.black)
    }
}
