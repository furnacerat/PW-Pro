import SwiftUI

class TransitionManager: ObservableObject {
    static let shared = TransitionManager()
    
    @Published var sweepOffset: CGFloat = UIScreen.main.bounds.width
    @Published var isSweeping = false
    
    func triggerSweep(action: (() -> Void)? = nil) {
        HapticManager.heavy()
        sweepOffset = UIScreen.main.bounds.width
        isSweeping = true
        
        withAnimation(.easeInOut(duration: 0.5)) {
            sweepOffset = -UIScreen.main.bounds.width
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            action?()
            // Reset for next time after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isSweeping = false
                self.sweepOffset = UIScreen.main.bounds.width
            }
        }
    }
}

struct SweepRevealView: View {
    let offset: CGFloat
    
    var body: some View {
        ZStack {
            // High-pressure Fan Sweep
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            Theme.sky500.opacity(0.3),
                            Theme.sky400,
                            Theme.sky500.opacity(0.3),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 300)
                .blur(radius: 20)
                .offset(x: offset)
            
            // Solid bar for sharp wipe
            Rectangle()
                .fill(Theme.sky500)
                .frame(width: 4)
                .glow(color: Theme.sky500, radius: 10)
                .offset(x: offset + 150)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
