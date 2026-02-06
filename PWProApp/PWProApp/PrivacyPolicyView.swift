import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Theme.slate900.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Privacy Policy")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(Theme.slate500)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Theme.slate900.opacity(0.8))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Last Updated: January 2026")
                            .font(.caption)
                            .foregroundColor(Theme.slate500)
                        
                        SectionHeader(title: "1. DATA COLLECTION")
                        Text("Pressure Washing Pro collects minimal data required for job tracking, including job addresses, customer names, and measurement data. This data is stored locally on your device or in your secure cloud storage.")
                            .font(Theme.bodyFont)
                            .foregroundColor(.white)
                        
                        SectionHeader(title: "2. LOCATION DATA")
                        Text("The app uses location data to provide local weather forecasts for your scheduled jobs. We do not track your location in the background or share it with third parties.")
                            .font(Theme.bodyFont)
                            .foregroundColor(.white)
                        
                        SectionHeader(title: "3. IMAGE DATA")
                        Text("Photos taken within the app (Before & After) are stored on your device gallery and associated with your job records. We do not access your private photo library beyond what you explicitly select.")
                            .font(Theme.bodyFont)
                            .foregroundColor(.white)
                        
                        SectionHeader(title: "4. DATA SECURITY")
                        Text("We prioritize your data security and use industry-standard encryption for any data transmitted for authentication or storage purposes.")
                            .font(Theme.bodyFont)
                            .foregroundColor(.white)
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
