import SwiftUI

// MARK: - Premium Visual Effects

/// Shimmer effect for premium elements
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    let angle: Double
    
    init(duration: Double = 2.0, angle: Double = 45) {
        self.duration = duration
        self.angle = angle
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.3),
                            .white.opacity(0.5),
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: phase)
                    .rotationEffect(.degrees(angle))
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    phase = 1000
                }
            }
    }
}

/// Glow effect for premium elements
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.4), radius: radius * 1.5, x: 0, y: 0)
            .shadow(color: color.opacity(0.2), radius: radius * 2, x: 0, y: 0)
    }
}

/// Floating animation for premium elements
struct FloatingModifier: ViewModifier {
    @State private var isFloating = false
    let amplitude: CGFloat
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -amplitude : amplitude)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isFloating.toggle()
                }
            }
    }
}

/// Pulse animation for attention
struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let scale: CGFloat
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? scale : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isPulsing.toggle()
                }
            }
    }
}

extension View {
    /// Add shimmer effect
    func shimmer(duration: Double = 2.0, angle: Double = 45) -> some View {
        self.modifier(ShimmerModifier(duration: duration, angle: angle))
    }
    
    /// Add glow effect
    func glow(color: Color, radius: CGFloat = 10) -> some View {
        self.modifier(GlowModifier(color: color, radius: radius))
    }
    
    /// Add floating animation
    func floating(amplitude: CGFloat = 5, duration: Double = 2.0) -> some View {
        self.modifier(FloatingModifier(amplitude: amplitude, duration: duration))
    }
    
    /// Add pulse animation
    func pulse(scale: CGFloat = 1.05, duration: Double = 1.0) -> some View {
        self.modifier(PulseModifier(scale: scale, duration: duration))
    }
}

// MARK: - Premium Components

/// Luxury gradient button
struct LuxuryButton: View {
    let title: String
    let icon: String?
    let gradient: LinearGradient
    let action: () -> Void
    var isLoading: Bool = false
    
    init(
        title: String,
        icon: String? = nil,
        gradient: LinearGradient = Theme.primaryGradient,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(title)
                    .font(Theme.industrialSubheading)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                ZStack {
                    // Gradient background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(gradient)
                    
                    // Shimmer overlay
                    if !isLoading {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.clear)
                            .shimmer(duration: 3.0)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .glow(color: Theme.sky500, radius: isLoading ? 5 : 15)
            .opacity(isLoading ? 0.7 : 1.0)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isLoading)
        .sensoryFeedback(.impact(weight: .medium), trigger: isLoading)
    }
}

/// Premium stat card with animation
struct PremiumStatCard: View {
    let title: String
    let value: String
    let change: String?
    let trend: TrendDirection
    let color: Color
    let icon: String
    
    @State private var isVisible = false
    
    enum TrendDirection {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return Theme.emerald500
            case .down: return Theme.red500
            case .neutral: return Theme.slate400
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and trend
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .glow(color: color, radius: 8)
                
                Spacer()
                
                if let change = change {
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                            .font(.system(size: 10, weight: .bold))
                        Text(change)
                            .font(Theme.labelText)
                    }
                    .foregroundColor(trend.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(trend.color.opacity(0.15))
                    .cornerRadius(8)
                }
            }
            
            // Value
            Text(value)
                .font(Theme.industrialHeading)
                .foregroundColor(.white)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 20)
            
            // Title
            Text(title)
                .font(Theme.labelText)
                .foregroundColor(Theme.slate400)
                .textCase(.uppercase)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                // Gradient background
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.15),
                                color.opacity(0.05),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Border
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [color.opacity(0.4), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: color.opacity(0.2), radius: 15, x: 0, y: 8)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Industrial Backgrounds

struct DiagonalStreaks: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    for i in stride(from: -height, to: width + height, by: 80) {
                        path.move(to: CGPoint(x: i, y: 0))
                        path.addLine(to: CGPoint(x: i + height, y: height))
                    }
                }
                .stroke(Color.white.opacity(0.02), lineWidth: 1.5)
            }
        }
    }
}

struct IndustrialBackground: View {
    var body: some View {
        ZStack {
            Theme.slate900.ignoresSafeArea()
            DiagonalStreaks().opacity(0.5)
            
            RadialGradient(
                colors: [Theme.sky500.opacity(0.05), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 500
            ).ignoresSafeArea()
        }
    }
}

// MARK: - Base Components

struct GlassCard<Content: View>: View {
    let content: Content
    var showBorder: Bool = true
    
    init(showBorder: Bool = true, @ViewBuilder content: () -> Content) {
        self.showBorder = showBorder
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Theme.glassGradient)
                    
                    if showBorder {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Theme.sky500.opacity(0.3), .white.opacity(0.1), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                }
            )
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
    }
}

struct NeonButton: View {
    let title: String
    let color: Color
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    
    init(title: String, color: Color = Theme.sky500, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title).font(Theme.labelText).textCase(.uppercase)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Theme.primaryGradient)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isLoading)
        .sensoryFeedback(.impact(weight: .light), trigger: isLoading)
    }
}


struct StatBadge: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(Theme.labelText).foregroundColor(Theme.slate400)
            Text(value).font(Theme.industrialSubheading).foregroundColor(color)
        }
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct WeatherMiniItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon).foregroundColor(Theme.sky500)
                Text(value).font(Theme.dataMonospace).fontWeight(.bold).foregroundColor(.white)
            }
            Text(label).font(.system(size: 8)).foregroundColor(Theme.slate500)
        }
    }
}

/// Premium Empty State with Action
struct PremiumEmptyState: View {
    let title: String
    let description: String
    let icon: String // SFSymbol Name
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(title: String, description: String, icon: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.description = description
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Theme.slate800)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Theme.slate700, style: StrokeStyle(lineWidth: 1, dash: [5]))
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(Theme.slate500)
                    .glow(color: Theme.sky500, radius: 10)
            }
            .padding(.bottom, 8)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(Theme.headingFont)
                    .foregroundColor(.white)
                Text(description)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.slate400)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Theme.sky500)
                        .cornerRadius(12)
                        .shadow(color: Theme.sky500.opacity(0.4), radius: 10, y: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.sky500.opacity(0.6), lineWidth: 1)
                        )
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.slate900)
    }
}
