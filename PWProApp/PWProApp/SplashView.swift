import SwiftUI

struct SplashView: View {
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            Theme.slate900
                .ignoresSafeArea()
            
            // 1. Spinning Water Vortex (Transparent Background)
            Image("AppLogoVortex")
                .resizable()
                .scaledToFill()
                .frame(width: 400, height: 400)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
                .scaleEffect(scale)
            
            // 2. Static Monogram (Transparent Background)
            Image("AppLogoMonogram")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .opacity(opacity)
                .scaleEffect(scale)
                .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 10)
            
            // 3. App Name
            VStack {
                Spacer()
                Text("PWPro")
                    .font(Theme.headingFont)
                    .foregroundColor(.white)
                    .tracking(10)
                    .opacity(opacity)
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Background rotation animation (smooth continuous)
            withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
            // Fade in and scale up with a spring for "pop"
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                opacity = 1.0
                scale = 1.0
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
