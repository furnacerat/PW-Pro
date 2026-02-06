import SwiftUI

struct AppLogoView: View {
    var size: CGFloat = 100
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 1. Outer Power Ring (Gradient & Pulse)
            Circle()
                .trim(from: 0.1, to: 0.9)
                .stroke(
                    LinearGradient(colors: [Theme.emerald500, Theme.sky500], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .shadow(color: Theme.sky500.opacity(0.3), radius: size * 0.1)
                
            // 2. Inner Glow
            Circle()
                .fill(
                    RadialGradient(colors: [Theme.sky500.opacity(0.1), .clear], center: .center, startRadius: 0, endRadius: size * 0.5)
                )
                .frame(width: size * 1.2, height: size * 1.2)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
            
            // 3. The "Droplet" Core
            WaterDropletShape()
                .fill(
                    LinearGradient(colors: [Theme.sky500, Theme.emerald500], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: size * 0.45, height: size * 0.6)
                .offset(y: -size * 0.05)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
            
            // 4. Highlight Sparkle
            Circle()
                .fill(.white.opacity(0.4))
                .frame(width: size * 0.08, height: size * 0.08)
                .offset(x: -size * 0.05, y: -size * 0.1)
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

struct WaterDropletShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width / 2, y: 0))
        path.addCurve(to: CGPoint(x: width / 2, y: height),
                     control1: CGPoint(x: width, y: height * 0.4),
                     control2: CGPoint(x: width, y: height))
        path.addCurve(to: CGPoint(x: width / 2, y: 0),
                     control1: CGPoint(x: 0, y: height),
                     control2: CGPoint(x: 0, y: height * 0.4))
        path.closeSubpath()
        return path
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
