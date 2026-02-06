import SwiftUI

// MARK: - Skeleton Loading Components

/// Shimmer effect modifier for skeleton screens
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

extension View {
    /// Apply shimmer animation effect
    func shimmer() -> some View {
        self.modifier(ShimmerEffect())
    }
}

/// Generic skeleton loading view
struct SkeletonView: View {
    var height: CGFloat = 80
    var cornerRadius: CGFloat = 12
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.2))
            .frame(height: height)
            .shimmer()
    }
}

/// Skeleton for client/job list items
struct SkeletonListItem: View {
    var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 8) {
                // Title placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 150, height: 16)
                
                // Subtitle placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 100, height: 12)
            }
            
            Spacer()
            
            // Trailing icon placeholder
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 24, height: 24)
        }
        .padding()
        .background(Theme.slate800.opacity(0.3))
        .cornerRadius(12)
        .shimmer()
    }
}

/// Skeleton for dashboard stat boxes
struct SkeletonStatBox: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 12)
            
            // Value
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 120, height: 24)
        }
        .padding()
        .background(Theme.slate800.opacity(0.3))
        .cornerRadius(12)
        .shimmer()
    }
}

/// Skeleton for cards
struct SkeletonCard: View {
    var height: CGFloat = 120
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 100, height: 16)
            
            // Content lines
            ForEach(0..<3) { _ in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 12)
            }
        }
        .padding()
        .background(Theme.slate800.opacity(0.3))
        .cornerRadius(16)
        .frame(height: height)
        .shimmer()
    }
}
