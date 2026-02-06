import SwiftUI

struct AppLogoView: View {
    var size: CGFloat = 100
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 1. Subtle Outer Glow
            Circle()
                .fill(
                    RadialGradient(colors: [Theme.sky500.opacity(0.15), .clear], center: .center, startRadius: 0, endRadius: size * 0.6)
                )
                .frame(width: size * 1.3, height: size * 1.3)
                .scaleEffect(isAnimating ? 1.05 : 0.95)
            
            // 2. The Final Logo
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.22)) // iOS icon shape approximation
                .shadow(color: .black.opacity(0.3), radius: size * 0.05, x: 0, y: size * 0.02)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// Preview
struct AppLogoView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Theme.slate900.ignoresSafeArea()
            AppLogoView(size: 200)
        }
    }
}
