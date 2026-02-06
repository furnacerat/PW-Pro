import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    enum LegalType: Identifiable {
        case terms, privacy
        var id: Self { self }
    }
    
    @State private var activeLegalSheet: LegalType?
    @State private var showSubscriptionPaywall = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("SETTINGS")
                            .font(Theme.headingFont)
                            .foregroundColor(.white)
                        Spacer()
                        AppLogoView(size: 40)
                    }
                    .padding(.bottom, 8)
                    
                    // Profile Section
                    NavigationLink(destination: BusinessProfileView()) {
                        GlassCard {
                            HStack(spacing: 16) {
                                #if os(macOS)
                                if let data = InvoiceManager.shared.businessSettings.logoData, let nsImage = NSImage(data: data) {
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                } else {
                                    ProfileCirclePlaceholder()
                                }
                                #else
                                if let data = InvoiceManager.shared.businessSettings.logoData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                } else {
                                    ProfileCirclePlaceholder()
                                }
                                #endif
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(InvoiceManager.shared.businessSettings.businessName)
                                        .font(Theme.bodyFont)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("Manage Business Branding")
                                        .font(.caption)
                                        .foregroundColor(Theme.sky500)
                                }
                                Spacer()
                                Image(systemName: "pencil")
                                    .foregroundColor(Theme.slate500)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // MARK: - Subscription Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SUBSCRIPTION")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate400)
                        
                        GlassCard {
                            VStack(spacing: 16) {
                                // Status Row
                                HStack {
                                    Image(systemName: subscriptionManager.isSubscribed ? "crown.fill" : "star.circle")
                                        .font(.system(size: 32))
                                        .foregroundColor(subscriptionManager.isSubscribed ? Theme.amber500 : Theme.slate500)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(subscriptionManager.isSubscribed ? "PWPro Premium" : "Free Plan")
                                            .font(Theme.bodyFont)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        if subscriptionManager.isSubscribed {
                                            Text("All features unlocked")
                                                .font(.caption)
                                                .foregroundColor(Theme.emerald500)
                                        } else {
                                            Text("\(subscriptionManager.freeScansRemaining) free AI scans remaining")
                                                .font(.caption)
                                                .foregroundColor(Theme.slate400)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if subscriptionManager.isSubscribed {
                                        Text("ACTIVE")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Theme.emerald500)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                }
                                
                                Divider()
                                    .background(Theme.slate700)
                                
                                // Action Buttons
                                if subscriptionManager.isSubscribed {
                                    // Manage Subscription
                                    Button(action: {
                                        openSubscriptionManagement()
                                    }) {
                                        HStack {
                                            Image(systemName: "creditcard.fill")
                                            Text("Manage Subscription")
                                            Spacer()
                                            Image(systemName: "arrow.up.right")
                                                .font(.caption)
                                        }
                                        .font(Theme.labelFont)
                                        .foregroundColor(Theme.sky500)
                                        .padding()
                                        .background(Theme.sky500.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    // Upgrade Button
                                    Button(action: {
                                        showSubscriptionPaywall = true
                                        HapticManager.impact(.medium)
                                    }) {
                                        HStack {
                                            Image(systemName: "sparkles")
                                            Text("Upgrade to Premium")
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                        }
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(
                                            LinearGradient(
                                                colors: [Theme.sky500, Theme.purple500],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    // Restore Purchases
                                    Button(action: {
                                        Task {
                                            await subscriptionManager.restorePurchases()
                                        }
                                    }) {
                                        Text("Restore Purchases")
                                            .font(.caption)
                                            .foregroundColor(Theme.sky500)
                                    }
                                }
                            }
                        }
                    }
                    
                    // App Sections
                    VStack(spacing: 12) {
                        SettingsRow(icon: "doc.text.fill", title: "Terms of Service", color: Theme.sky500) {
                            activeLegalSheet = .terms
                        }
                        
                        SettingsRow(icon: "shield.fill", title: "Privacy Policy", color: Theme.sky500) {
                            activeLegalSheet = .privacy
                        }
                        
                        SettingsRow(icon: "bell.fill", title: "Notifications", color: Theme.sky500) {
                            // Action
                        }
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Logout Button
                    Button(action: {
                        Task {
                            await authManager.logout()
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Logout")
                        }
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.red500)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.red500.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.red500.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Text("Version 1.0.0 (Build 42)")
                        .font(.caption2)
                        .foregroundColor(Theme.slate500)
                }
                .padding()
            }
            .background(Theme.slate900)
            .sheet(item: $activeLegalSheet) { type in
                switch type {
                case .terms: 
                    TermsAndConditionsView()
                        .environmentObject(authManager)
                case .privacy: 
                    PrivacyPolicyView()
                }
            }
            .sheet(isPresented: $showSubscriptionPaywall) {
                PaywallView()
                    .environmentObject(subscriptionManager)
            }
        }
    }
    
    private func openSubscriptionManagement() {
        #if os(iOS)
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

struct ProfileCirclePlaceholder: View {
    var body: some View {
        Image(systemName: "person.crop.circle.fill")
            .font(.system(size: 60))
            .foregroundColor(Theme.slate700)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 30)
                Text(title)
                    .font(Theme.labelFont)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.slate500)
            }
            .padding()
            .background(Theme.slate800.opacity(0.5))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
