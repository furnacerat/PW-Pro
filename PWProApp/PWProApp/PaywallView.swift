import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedPackage: Package?
    
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
                    
                    // Package Selection
                    if !subscriptionManager.availablePackages.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(subscriptionManager.availablePackages, id: \.identifier) { package in
                                PackageCard(
                                    package: package,
                                    isSelected: selectedPackage?.identifier == package.identifier
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedPackage = package
                                        HapticManager.selection()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .onAppear {
                            // Default to yearly if available
                            if selectedPackage == nil {
                                selectedPackage = subscriptionManager.yearlyPackage ?? subscriptionManager.availablePackages.first
                            }
                        }
                        
                        // CTA Button
                        VStack(spacing: 12) {
                            Button(action: {
                                guard let package = selectedPackage else { return }
                                Task {
                                    try? await subscriptionManager.purchase(package: package)
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
                            .disabled(subscriptionManager.purchaseInProgress || selectedPackage == nil)
                            
                            if let package = selectedPackage {
                                Text("Free for 7 days, then \(package.localizedPriceString)\(package.packageType == .annual ? "/year" : "/month")\nCancel anytime • No commitment")
                                    .font(.caption)
                                    .foregroundColor(Theme.slate500)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        // Loading or fallback state
                        VStack(spacing: 24) {
                            if subscriptionManager.errorMessage != nil {
                                Text("Unable to load subscription options")
                                    .foregroundColor(Theme.red500)
                                
                                Button("Retry") {
                                    Task {
                                        await subscriptionManager.fetchOfferings()
                                    }
                                }
                                .foregroundColor(Theme.sky500)
                            } else {
                                ProgressView()
                                    .tint(Theme.sky500)
                                Text("Loading options...")
                                    .foregroundColor(Theme.slate400)
                            }
                        }
                        .padding(40)
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
                    
                    // Features List
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("EVERYTHING INCLUDED")
                                .font(Theme.labelFont)
                                .foregroundColor(Theme.slate400)
                            
                            ForEach(SubscriptionTier.monthly.features, id: \.self) { feature in
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
        .onAppear {
            Task {
                await subscriptionManager.fetchOfferings()
            }
        }
    }
}

// MARK: - Package Card

struct PackageCard: View {
    let package: Package
    let isSelected: Bool
    let action: () -> Void
    
    var isYearly: Bool {
        package.packageType == .annual
    }
    
    var savingsText: String? {
        guard isYearly, let _ = package.storeProduct.subscriptionPeriod else { return nil }
        // $79.95/mo x 12 = $959.40, vs $799.95/yr = 17% savings
        return "Save 17%"
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(isYearly ? "Yearly" : "Monthly")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if let savings = savingsText {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.emerald500)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        if isYearly {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.amber500)
                                .foregroundColor(.black)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(package.localizedPriceString + (isYearly ? "/year" : "/month"))
                        .font(.subheadline)
                        .foregroundColor(Theme.slate400)
                    
                    if isYearly {
                        Text("That's just \(monthlyEquivalent)/month")
                            .font(.caption)
                            .foregroundColor(Theme.emerald500)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? Theme.sky500 : Theme.slate600)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.slate800.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Theme.sky500 : Theme.slate700, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    var monthlyEquivalent: String {
        let price = package.storeProduct.price as Decimal
        let monthly = price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = package.storeProduct.priceFormatter?.locale ?? Locale.current
        return formatter.string(from: monthly as NSDecimalNumber) ?? ""
    }
}

// MARK: - Value Prop Card

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
