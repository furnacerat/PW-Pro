import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    enum LegalType: Identifiable {
        case terms, privacy
        var id: Self { self }
    }
    
    @State private var activeLegalSheet: LegalType?
    
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
                        authManager.logout()
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
        }
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
