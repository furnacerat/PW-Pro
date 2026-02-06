import SwiftUI

struct TermsAndConditionsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    var isMandatory: Bool = false
    
    var body: some View {
        ZStack {
            Theme.slate900.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Terms of Service")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Spacer()
                    if !isMandatory {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(Theme.slate500)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(Theme.slate900.opacity(0.8))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Last Updated: January 2026")
                            .font(.caption)
                            .foregroundColor(Theme.slate500)
                        
                        SectionHeader(title: "1. REFERENCE ONLY DISCLAIMER")
                        
                        Text("All calculations, mixing ratios, and chemical suggestions provided by **Pressure Washing Pro** are for **REFERENCE PURPOSES ONLY**. This application is designed as a tool to assist professionals, but it does not replace professional training, experience, or onsite assessment.")
                            .font(Theme.bodyFont)
                            .foregroundColor(.white)
                        
                        SectionHeader(title: "2. USER RESPONSIBILITY (CYA)")
                        
                        Text("As the user of this application, you acknowledge and agree that you are **SOLELY RESPONSIBLE** for:")
                            .font(Theme.bodyFont)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            BulletPoint(text: "Reviewing and understanding all Chemical Manufacturer Safety Data Sheets (SDS/MSDS).")
                            BulletPoint(text: "Verifying all mixing ratios prior to application to ensure property and personal safety.")
                            BulletPoint(text: "Testing chemicals on an inconspicuous area before full-scale cleaning.")
                            BulletPoint(text: "Safety protocols, including wearing appropriate PPE and following local regulations.")
                        }
                        .padding(.leading)
                        
                        SectionHeader(title: "3. LIMITATION OF LIABILITY")
                        
                        Text("**PRESSURE WASHING PRO** and its creators shall NOT be held liable for any damages, including but not limited to property damage, plant death, chemical burns, or loss of revenue resulting from the use or misuse of the information provided in this app.")
                            .foregroundColor(Theme.amber500)
                            .padding()
                            .background(Theme.amber500.opacity(0.1))
                            .cornerRadius(8)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        
                        SectionHeader(title: "4. SUBSCRIPTION & TRIAL")
                        
                        Text("This app offers a 7-Day Free Trial. Upon expiration, access to pro features will require a paid subscription. You may cancel at any time through your account settings.")
                            .font(Theme.bodyFont)
                            .foregroundColor(.white)
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
                
                if isMandatory {
                    VStack(spacing: 12) {
                        Text("By tapping below, you confirm you have read and agree to the Terms of Service, specifically the Reference Disclaimer.")
                            .font(.caption2)
                            .foregroundColor(Theme.slate500)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            authManager.acceptTerms()
                        } label: {
                            Text("I Understand & Accept")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.sky500)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.top)
                    .background(Theme.slate900)
                    .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(Theme.labelFont)
            .foregroundColor(Theme.sky500)
            .padding(.top, 10)
    }
}

struct BulletPoint: View {
    let text: String
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .foregroundColor(Theme.sky500)
            Text(text)
                .font(.caption)
                .foregroundColor(Theme.slate400)
        }
    }
}
