import SwiftUI

struct BusinessDocumentsView: View {
    @ObservedObject var invoiceManager = InvoiceManager.shared
    @State private var showEditor = false
    @State private var editingDoc: BusinessDocument?
    @State private var printingDoc: BusinessDocument?
    
    var body: some View {
        List {
            if invoiceManager.businessSettings.documents.isEmpty {
                Text("No documents added yet. Add terms, waivers, or contracts here.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(invoiceManager.businessSettings.documents) { doc in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(doc.title)
                                .font(.headline)
                                .foregroundColor(.white)
                            if doc.isDefault {
                                Text("DEFAULT")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.sky500)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                        Text(doc.content)
                            .font(.caption)
                            .foregroundColor(Theme.slate500)
                            .lineLimit(2)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingDoc = doc
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            if let idx = invoiceManager.businessSettings.documents.firstIndex(where: { $0.id == doc.id }) {
                                invoiceManager.businessSettings.documents.remove(at: idx)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                             printingDoc = doc
                        } label: {
                            Label("Print", systemImage: "printer")
                        }
                        .tint(Theme.sky500)
                    }
                }
            }
        }
        .navigationTitle("Business Documents")
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editingDoc = BusinessDocument(title: "", content: "")
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $editingDoc) { doc in
            DocumentEditorSheet(document: doc) { newDoc in
                if let idx = invoiceManager.businessSettings.documents.firstIndex(where: { $0.id == doc.id }) {
                    invoiceManager.businessSettings.documents[idx] = newDoc
                } else {
                    invoiceManager.businessSettings.documents.append(newDoc)
                }
                editingDoc = nil
            }
        }
        .sheet(item: $printingDoc) { doc in
             NavigationStack {
                 ShareLink(item: renderPDF(for: doc), preview: SharePreview(doc.title)) {
                     Label("Print / Share PDF", systemImage: "printer")
                         .padding()
                         .background(Theme.sky500)
                         .foregroundColor(.white)
                         .cornerRadius(12)
                 }
                 .navigationTitle("Print Document")
                 .toolbar {
                     ToolbarItem(placement: .cancellationAction) {
                         Button("Close") { printingDoc = nil }
                     }
                 }
                 .frame(maxWidth: .infinity, maxHeight: .infinity)
                 .background(Color.gray.opacity(0.1))
             }
             .presentationDetents([.medium])
        }
    }

    @MainActor
    private func renderPDF(for doc: BusinessDocument) -> URL {
        let renderer = ImageRenderer(content: PrintDocumentView(document: doc))
        let url = URL.documentsDirectory.appending(path: "\(doc.title).pdf")
        
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

struct DocumentEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var document: BusinessDocument
    var onSave: (BusinessDocument) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Document Info") {
                    TextField("Title (e.g. Liability Waiver)", text: $document.title)
                    Toggle("Include by default on new contracts", isOn: $document.isDefault)
                }
                
                Section("Content") {
                    TextEditor(text: $document.content)
                        .frame(minHeight: 300)
                }
            }
            .navigationTitle("Edit Document")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(document)
                        dismiss()
                    }
                    .disabled(document.title.isEmpty)
                }
            }
        }
    }
}



struct PrintDocumentView: View {
    let document: BusinessDocument
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
             }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text(document.title.uppercased())
                    .font(.largeTitle.bold())
                
                Text(document.content)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding(40)
        .frame(width: 612)
        .background(Color.white)
        .foregroundColor(.black)
    }
}
