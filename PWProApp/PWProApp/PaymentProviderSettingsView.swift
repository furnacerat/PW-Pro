import SwiftUI

struct PaymentProviderSettingsView: View {
    @ObservedObject var invoiceManager = InvoiceManager.shared
    @State private var showingInfo = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PaymentProviderHeader()
                
                ProviderSelectionSection()
                
                ConfigurationSection(showingInfo: $showingInfo)
                
                ConnectionStatusFooter()
            }
            .padding()
        }
        .background(Theme.slate900)
        .navigationTitle("Payments")
        .alert("Finding your link", isPresented: $showingInfo) {
            Button("Got it") { }
        } message: {
            Text("Go to your \(invoiceManager.businessSettings.paymentProvider.rawValue) dashboard and find your 'Payment Link' or 'Public Profile URL'. Copy and paste that full URL here.")
        }
    }
}

struct PaymentProviderHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "creditcard.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.purple500)
            
            Text("Payment Integration")
                .font(Theme.headingFont)
                .foregroundColor(.white)
            
            Text("Link your preferred payment system to include direct pay links in your invoices.")
                .font(.caption)
                .foregroundColor(Theme.slate400)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 20)
    }
}

struct ProviderSelectionSection: View {
    @ObservedObject var invoiceManager = InvoiceManager.shared
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("SELECT PROVIDER")
                    .font(Theme.labelFont)
                    .foregroundColor(Theme.slate500)
                
                ForEach(PaymentProvider.allCases, id: \.self) { provider in
                    Button {
                        withAnimation {
                            invoiceManager.businessSettings.paymentProvider = provider
                        }
                    } label: {
                        HStack {
                            Image(systemName: provider.icon)
                                .foregroundColor(invoiceManager.businessSettings.paymentProvider == provider ? .white : Theme.sky500)
                                .frame(width: 32)
                            
                            Text(provider.rawValue)
                                .font(Theme.bodyFont)
                                .foregroundColor(invoiceManager.businessSettings.paymentProvider == provider ? .white : Theme.slate300)
                            
                            Spacer()
                            
                            if invoiceManager.businessSettings.paymentProvider == provider {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(invoiceManager.businessSettings.paymentProvider == provider ? Theme.sky500 : Theme.slate800.opacity(0.5))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ConfigurationSection: View {
    @ObservedObject var invoiceManager = InvoiceManager.shared
    @Binding var showingInfo: Bool
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("PROVIDER CONFIGURATION")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate500)
                    Spacer()
                    Button {
                        showingInfo.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(Theme.sky500)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(labelForProvider(invoiceManager.businessSettings.paymentProvider))
                        .font(.caption2.bold())
                        .foregroundColor(Theme.slate400)
                    
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(Theme.slate500)
                        TextField("https://buy.stripe.com/...", text: $invoiceManager.businessSettings.paymentLink)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .background(Theme.slate800)
                    .cornerRadius(12)
                }
                
                Text("This link will be attached to every invoice you send to clients.")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.slate500)
                    .italic()
            }
        }
    }
    
    private func labelForProvider(_ provider: PaymentProvider) -> String {
        switch provider {
        case .stripe: return "STRIPE PAYMENT LINK"
        case .square: return "SQUARE CHECKOUT URL"
        case .paypal: return "PAYPAL.ME LINK"
        case .custom: return "CUSTOM CHECKOUT URL"
        }
    }
}

struct ConnectionStatusFooter: View {
    @ObservedObject var invoiceManager = InvoiceManager.shared
    
    var body: some View {
        HStack {
            Circle()
                .fill(invoiceManager.businessSettings.paymentLink.isEmpty ? Theme.red500 : Theme.emerald500)
                .frame(width: 8, height: 8)
            Text(invoiceManager.businessSettings.paymentLink.isEmpty ? "Not Connected" : "Ready to accept payments")
                .font(.caption)
                .foregroundColor(Theme.slate400)
            Spacer()
        }
        .padding(.horizontal)
    }
}
