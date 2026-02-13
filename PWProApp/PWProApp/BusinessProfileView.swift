import SwiftUI
import PhotosUI

struct BusinessProfileView: View {
    @ObservedObject var invoiceManager = InvoiceManager.shared
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo Upload Section
                VStack(spacing: 16) {
                    let logoData = invoiceManager.businessSettings.logoData
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        BusinessLogoView(logoData: logoData)
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task { @MainActor in
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                invoiceManager.businessSettings.logoData = data
                            }
                        }
                    }
                    
                    if invoiceManager.businessSettings.logoData != nil {
                        Button("Remove Logo") {
                            invoiceManager.businessSettings.logoData = nil
                        }
                        .font(.caption)
                        .foregroundColor(Theme.red500)
                    }
                }
                .padding(.top)
                
                // Business Details
                GlassCard {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("BUSINESS INFORMATION")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                        
                        CustomBrandInput(label: "BUSINESS NAME", text: $invoiceManager.businessSettings.businessName, icon: "briefcase.fill")
                        CustomBrandInput(label: "ADDRESS", text: $invoiceManager.businessSettings.businessAddress, icon: "map.fill")
                        CustomBrandInput(label: "PHONE", text: $invoiceManager.businessSettings.businessPhone, icon: "phone.fill")
                        CustomBrandInput(label: "EMAIL", text: $invoiceManager.businessSettings.businessEmail, icon: "envelope.fill")
                    }
                }
                
                // Terms of Service
                VStack(alignment: .leading, spacing: 12) {
                    Text("CONTRACT TERMS (PRELOADS ON INVOICES/ESTIMATES)")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate500)
                    
                    TextEditor(text: $invoiceManager.businessSettings.customTerms)
                        .frame(height: 120)
                        .padding(12)
                        .background(Theme.slate800)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.system(size: 14))
                }
                
                // Legal & Documents
                GlassCard {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("LEGAL & DOCUMENTS")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                        
                        NavigationLink(destination: BusinessDocumentsView()) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(Theme.sky500)
                                Text("Manage Custom Documents / Contracts")
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Theme.slate600)
                            }
                        }
                    }
                }
                
                // Review Settings
                GlassCard {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("REVIEW AUTOMATION")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                        
                        NavigationLink(destination: ReviewSettingsView()) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(Theme.amber500)
                                Text("Manage Review Links & Templates")
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Theme.slate600)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Theme.slate900)
        .navigationTitle("Business Branding")
        .preferredColorScheme(.dark)
    }
}

struct LogoPlaceholder: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(Theme.sky500)
            Text("Upload Business Logo")
                .font(.caption.bold())
                .foregroundColor(Theme.slate400)
        }
        .frame(width: 200, height: 120)
        .background(Theme.slate800.opacity(0.5))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.slate700, style: StrokeStyle(lineWidth: 1, dash: [5]))
        )
    }
}

struct CustomBrandInput: View {
    let label: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Theme.slate500)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.sky500)
                    .frame(width: 20)
                TextField(label, text: $text)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Theme.slate900.opacity(0.5))
            .cornerRadius(12)
        }
    }
}

struct BusinessLogoView: View {
    let logoData: Data?
    
    var body: some View {
        VStack(spacing: 12) {
            #if os(macOS)
            if let data = logoData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .background(Theme.slate800)
                    .cornerRadius(16)
            } else {
                LogoPlaceholder()
            }
            #else
            if let data = logoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .background(Theme.slate800)
                    .cornerRadius(16)
            } else {
                LogoPlaceholder()
            }
            #endif
        }
    }
}
