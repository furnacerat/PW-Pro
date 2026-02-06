import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        ZStack {
            // Background
            Theme.slate900.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.sky500, Theme.purple500],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Unlock PWPro Premium")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Join 5,000+ pros saving 10+ hours/week")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.slate400)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Pricing Card
                    if let product = subscriptionManager.availableProducts.first {
                        PricingCard(price: product.displayPrice)
                        
                        // CTA Button
                        VStack(spacing: 12) {
                            Button(action: {
                                Task {
                                    do {
                                        try await subscriptionManager.purchase(product)
                                    } catch {
                                        print("Purchase failed: \(error)")
                                    }
                                }
                            }) {
                                HStack {
                                    if subscriptionManager.purchaseInProgress {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Start Free Trial")
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Theme.sky500, Theme.purple500],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                            .disabled(subscriptionManager.purchaseInProgress)
                            
                            Text("Free for 14 days, then \(product.displayPrice)/month\nCancel anytime • No commitment")
                                .font(.caption)
                                .foregroundColor(Theme.slate500)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                    } else {
                        // Fallback/Simulated Pricing Card for Demo
                        VStack(spacing: 24) {
                            PricingCard(price: SubscriptionTier.pro.price)
                            
                            Button(action: {
                                // Simulate purchase for demo
                                withAnimation {
                                    subscriptionManager.isSubscribed = true
                                    dismiss()
                                }
                            }) {
                                Text("Upgrade to Premium ($74.95)")
                                    .font(.system(size: 18, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Theme.sky500)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal)
                            
                            Text("Simulated purchase for development purposes")
                                .font(.caption2)
                                .foregroundColor(Theme.slate600)
                        }
                    }
                    
                    // Social Proof
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                ForEach(0..<5) { _ in
                                    Image(systemName: "star.fill")
                                        .foregroundColor(Theme.amber500)
                                }
                                Spacer()
                            }
                            
                            Text("\"PWPro saved me 15 hours a week. The AI estimator alone paid for itself in the first month.\"")
                                .font(Theme.bodyFont)
                                .foregroundColor(.white)
                                .italic()
                            
                            Text("— Mike T., Texas Power Washing")
                                .font(Theme.labelFont)
                                .foregroundColor(Theme.slate400)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Value Props Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ValuePropCard(icon: "clock.fill", title: "Save 10+ hrs/week", color: Theme.emerald500)
                        ValuePropCard(icon: "dollarsign.circle.fill", title: "Increase revenue 20%", color: Theme.sky500)
                        ValuePropCard(icon: "sparkles", title: "AI-powered tools", color: Theme.purple500)
                        ValuePropCard(icon: "shield.checkmark.fill", title: "Cancel anytime", color: Theme.amber500)
                    }
                    .padding(.horizontal)
                    
                    // Footer Links
                    VStack(spacing: 8) {
                        Button("Restore Purchases") {
                            Task {
                                await subscriptionManager.restorePurchases()
                            }
                        }
                        .foregroundColor(Theme.sky500)
                        
                        HStack(spacing: 16) {
                            Button("Terms") {
                                // Open terms
                            }
                            .foregroundColor(Theme.slate500)
                            
                            Text("•")
                                .foregroundColor(Theme.slate700)
                            
                            Button("Privacy") {
                                // Open privacy
                            }
                            .foregroundColor(Theme.slate500)
                        }
                        .font(.caption)
                    }
                    .padding(.bottom, 32)
                }
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(Theme.slate500)
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

struct ValuePropCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct PricingCard: View {
    let price: String
    
    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                // Price
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(price)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        Text("/month")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.slate400)
                    }
                    
                    Text("14-Day Free Trial")
                        .font(Theme.labelFont)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Theme.emerald500)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                
                Divider()
                    .background(Theme.slate700)
                
                // Features
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(SubscriptionTier.pro.features, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.emerald500)
                                .font(.system(size: 16))
                            
                            Text(feature)
                                .font(Theme.bodyFont)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(4)
        }
        .padding(.horizontal)
    }
}
