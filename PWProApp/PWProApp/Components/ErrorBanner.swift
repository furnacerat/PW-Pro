import SwiftUI

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        GlassCard(showBorder: true) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.red500)
                
                Text(message)
                    .font(Theme.bodyFont)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.slate400)
                        .padding(8)
                        .background(Theme.slate800.opacity(0.5))
                        .clipShape(Circle())
                }
            }
        }
        .background(Theme.red500.opacity(0.1))
        .cornerRadius(20) // Match GlassCard radius
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        ErrorBanner(message: "Failed to load data. Please check your internet connection and try again.", onDismiss: {})
    }
}
