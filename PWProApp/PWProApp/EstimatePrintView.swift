import SwiftUI

struct EstimatePrintView: View {
    let estimate: SavedEstimate
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
                        Text("ESTIMATE")
                            .font(.largeTitle.bold())
                            .foregroundColor(.primary)
                        Text(estimate.displayDate, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Client Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("PREPARED FOR")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text(estimate.client.name)
                        .font(.headline)
                    Text(estimate.client.address)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Scope of Work (Estimate Items)
                VStack(alignment: .leading, spacing: 12) {
                    Text("PROPOSED SERVICES")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    ForEach(estimate.estimate.items) { item in
                        HStack {
                            Text(item.displayName)
                            if item.squareFootage > 0 {
                                Text("(\(Int(item.squareFootage)) sq ft)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            // Calculate item price properly based on pricing model
                            Text(getItemPriceString(item))
                        }
                        .font(.body)
                    }
                    
                    Divider()
                    
                    HStack {
                        Spacer()
                        Text("Total Estimate: \(String(format: "$%.2f", estimate.totalPrice))")
                            .font(.headline)
                    }
                }
                
                // Standard Terms
                VStack(alignment: .leading, spacing: 8) {
                    Text("TERMS")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text("This is an estimate, not a final invoice. Pricing subject to change if scope of work changes.")
                        .font(.caption)
                        .foregroundColor(.primary)
                    Text(invoiceManager.businessSettings.customTerms)
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                        Text("Approved By").font(.caption)
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
        .navigationTitle("Estimate Preview")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareEstimateButton(estimate: estimate, selectedDocs: selectedDocuments)
            }
        }
    }
    
    func getItemPriceString(_ item: EstimateItem) -> String {
        // Simple proportional calculation for display if needed, 
        // or just use item total if available. 
        // Estimate saved struct doesn't have individual item totals stored easily accessible in all versions,
        // but we can approximate or just show total.
        // For now returning blank for individual lines if not strictly tracked, or calculate from unit price.
        // The SavedEstimate re-construction in EstimateManager does try to calc totals.
        return String(format: "$%.2f", item.totalPrice > 0 ? item.totalPrice : (item.squareFootage * estimate.estimate.pricePerSqFt))
    }
}

// Wrapper to share rendered content
struct ShareEstimateButton: View {
    let estimate: SavedEstimate
    let selectedDocs: Set<UUID>
    
    var body: some View {
        ShareLink(item: renderPDF(), preview: SharePreview("Estimate for \(estimate.client.name)")) {
            Label("Share PDF", systemImage: "square.and.arrow.up")
        }
    }
    
    @MainActor
    private func renderPDF() -> URL {
        let renderer = ImageRenderer(content: EstimatePrintingView(estimate: estimate, selectedDocs: selectedDocs))
        let url = URL.documentsDirectory.appending(path: "Estimate-\(estimate.client.name).pdf")
        
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
struct EstimatePrintingView: View {
    let estimate: SavedEstimate
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
                     Text("ESTIMATE")
                         .font(.largeTitle.bold())
                     Text(estimate.displayDate, style: .date)
                 }
             }
            
            Divider()
            
            // Client Info
            VStack(alignment: .leading, spacing: 8) {
                Text("PREPARED FOR")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text(estimate.client.name)
                    .font(.headline)
                Text(estimate.client.address)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Scope
            VStack(alignment: .leading, spacing: 12) {
                Text("PROPOSED SERVICES")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                ForEach(estimate.estimate.items) { item in
                    HStack {
                        Text(item.displayName)
                        Spacer()
                        Text(String(format: "$%.2f", item.totalPrice))
                    }
                }
                Divider()
                HStack {
                    Spacer()
                    Text("Total: \(String(format: "$%.2f", estimate.totalPrice))")
                        .font(.headline)
                }
            }
            
            // Terms
            VStack(alignment: .leading, spacing: 8) {
                Text("TERMS")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text("This is an estimate, not a final invoice. Pricing subject to change if scope of work changes.")
                    .font(.caption)
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
                    Text("Approved By").font(.caption)
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
