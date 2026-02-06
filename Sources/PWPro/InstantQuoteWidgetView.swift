import SwiftUI

struct InstantQuoteWidgetView: View {
    @State private var address: String = ""
    @State private var email: String = ""
    @State private var selectedServices: Set<SurfaceType> = []
    @State private var estimatedPrice: Double = 0
    @State private var showResult = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("GET AN INSTANT ESTIMATE")
                .font(Theme.labelFont)
                .foregroundColor(Theme.sky500)
            
            if !showResult {
                VStack(spacing: 16) {
                    CustomWidgetInput(label: "Property Address", text: $address, icon: "mappin.and.ellipse")
                    CustomWidgetInput(label: "Email Address", text: $email, icon: "envelope.fill")
                    
                    Text("Select Services")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.slate400)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach([SurfaceType.siding, .concrete, .roof, .gutters], id: \.self) { surface in
                            Button {
                                if selectedServices.contains(surface) {
                                    selectedServices.remove(surface)
                                } else {
                                    selectedServices.insert(surface)
                                }
                            } label: {
                                Text(surface.rawValue)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedServices.contains(surface) ? Theme.sky500 : Theme.slate800)
                                    .foregroundColor(selectedServices.contains(surface) ? .white : Theme.slate400)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    NeonButton(title: "Calculate My Quote", color: Theme.emerald500) {
                        calculateQuote()
                    }
                    .disabled(address.isEmpty || email.isEmpty || selectedServices.isEmpty)
                }
            } else {
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.emerald500)
                    
                    VStack(spacing: 8) {
                        Text("ESTIMATED TOTAL")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate400)
                        Text("$\(Int(estimatedPrice)) - $\(Int(estimatedPrice * 1.2))")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("We've sent a detailed breakdown to \(email). Our team will follow up at \(address) within 24 hours.")
                        .font(.caption)
                        .foregroundColor(Theme.slate400)
                        .multilineTextAlignment(.center)
                    
                    NeonButton(title: "Book Professional Visit", color: Theme.sky500) {
                        showResult = false
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(24)
        .background(Theme.slate900)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Theme.sky500.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Theme.sky500.opacity(0.1), radius: 20)
        .padding()
    }
    
    private func calculateQuote() {
        // Mock logic: $250 base + $150 per service
        estimatedPrice = 250 + (Double(selectedServices.count) * 150)
        withAnimation {
            showResult = true
        }
        
        // Push to CRM as Lead
        let newLead = Client(
            name: "Web Lead (\(email))",
            email: email,
            phone: "",
            address: address,
            status: .lead,
            tags: ["Web Quote", "Automated"],
            jobHistory: [],
            interactions: [InteractionLog(date: Date(), type: .email, notes: "Automated instant quote generated.")]
        )
        ClientManager.shared.addClient(newLead)
    }
}

struct CustomWidgetInput: View {
    let label: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Theme.slate500)
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.sky500)
                TextField("", text: $text)
                    .foregroundColor(.white)
                    .font(.caption)
            }
            .padding(12)
            .background(Theme.slate800)
            .cornerRadius(12)
        }
    }
}

#Preview {
    InstantQuoteWidgetView()
        .preferredColorScheme(.dark)
}
