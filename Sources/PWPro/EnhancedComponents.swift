import SwiftUI

// MARK: - Enhanced Loading Views

struct SkeletonView: View {
    @State private var isAnimating = false
    
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(width: CGFloat = 100, height: CGFloat = 20, cornerRadius: CGFloat = 4) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.3))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? width : -width)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .clipped()
            .onAppear {
                isAnimating = true
            }
    }
}

struct SkeletonCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonView(width: 120, height: 20, cornerRadius: 4)
            SkeletonView(width: .infinity, height: 16, cornerRadius: 4)
            SkeletonView(width: .infinity, height: 16, cornerRadius: 4)
            SkeletonView(width: 80, height: 14, cornerRadius: 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct SkeletonRowView: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonView(width: 40, height: 40, cornerRadius: 20)
            
            VStack(alignment: .leading, spacing: 8) {
                SkeletonView(width: 150, height: 16, cornerRadius: 4)
                SkeletonView(width: 200, height: 14, cornerRadius: 4)
            }
            
            Spacer()
            
            SkeletonView(width: 60, height: 20, cornerRadius: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Animated Button Styles

struct AnimatedButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    
    init(backgroundColor: Color = .accentColor, foregroundColor: Color = .white) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            )
    }
}

struct PulsingButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    
    @State private var isPulsing = false
    
    init(backgroundColor: Color = .red, foregroundColor: Color = .white) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .scaleEffect(configuration.isPressed ? 0.95 : (isPulsing ? 1.05 : 1.0))
                    .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Enhanced Card Views

struct AnimatedCard<Content: View>: View {
    let content: Content
    let onTap: (() -> Void)?
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    init(onTap: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.onTap = onTap
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: .black.opacity(isPressed ? 0.2 : (isHovered ? 0.15 : 0.1)),
                        radius: isPressed ? 8 : (isHovered ? 6 : 4),
                        x: 0,
                        y: isPressed ? 4 : 2
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onTapGesture {
                onTap?()
            }
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}

struct GlassCard<Content: View>: View {
    let content: Content
    let opacity: Double
    
    init(opacity: Double = 0.8, @ViewBuilder content: () -> Content) {
        self.opacity = opacity
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(opacity))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
    }
}

// MARK: - Progress Indicators

struct CircularLoadingView: View {
    @State private var isRotating = false
    let size: CGFloat
    let lineWidth: CGFloat
    let color: Color
    
    init(size: CGFloat = 40, lineWidth: CGFloat = 4, color: Color = .accentColor) {
        self.size = size
        self.lineWidth = lineWidth
        self.color = color
    }
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                )
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isRotating
            )
            .onAppear {
                isRotating = true
            }
    }
}

struct DotsLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Animated Transitions

struct SlideTransition: ViewModifier {
    let edge: Edge
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: edge == .leading ? (isActive ? 0 : -100) : (edge == .trailing ? (isActive ? 0 : 100) : 0),
                y: edge == .top ? (isActive ? 0 : -100) : (edge == .bottom ? (isActive ? 0 : 100) : 0)
            )
            .opacity(isActive ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

extension View {
    func slideTransition(from edge: Edge, isActive: Bool) -> some View {
        modifier(SlideTransition(edge: edge, isActive: isActive))
    }
}

// MARK: - Enhanced List Views

struct AnimatedListRow<Item: Identifiable, Content: View>: View {
    let item: Item
    let content: (Item) -> Content
    
    @State private var isAppearing = false
    
    init(item: Item, @ViewBuilder content: @escaping (Item) -> Content) {
        self.item = item
        self.content = content
    }
    
    var body: some View {
        content(item)
            .scaleEffect(isAppearing ? 1.0 : 0.95)
            .opacity(isAppearing ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.3).delay(0.1), value: isAppearing)
            .onAppear {
                isAppearing = true
            }
    }
}

// MARK: - Enhanced Search Bar

struct AnimatedSearchBar: View {
    @Binding var searchText: String
    @State private var isExpanded = false
    @State private var isActive = false
    
    let placeholder: String
    let onSearchChanged: (String) -> Void
    
    init(
        searchText: Binding<String>,
        placeholder: String = "Search...",
        onSearchChanged: @escaping (String) -> Void = { _ in }
    ) {
        self._searchText = searchText
        self.placeholder = placeholder
        self.onSearchChanged = onSearchChanged
    }
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(placeholder, text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isActive = true
                        }
                    }
                    .onChange(of: searchText) { newValue in
                        onSearchChanged(newValue)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        onSearchChanged("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            .scaleEffect(isActive ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isActive)
            
            if isActive {
                Button("Cancel") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isActive = false
                        searchText = ""
                        onSearchChanged("")
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.accentColor)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .scaleEffect(isPulsing ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: isPulsing
                )
        }
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Enhanced Tab Item

struct EnhancedTabItem: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .scaleEffect(isSelected ? 1.2 : 1.0)
            
            Text(title)
                .font(.caption)
                .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Refresh Control

struct AnimatedRefreshControl: View {
    let isLoading: Bool
    let onRefresh: () -> Void
    
    @State private var isRotating = false
    
    var body: some View {
        Button(action: {
            onRefresh()
            withAnimation {
                isRotating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isRotating = false
            }
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.title2)
                .foregroundColor(.secondary)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .animation(.easeInOut(duration: 1.0), value: isRotating)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.5 : 1.0)
    }
}

// MARK: - Badge View

struct BadgeView: View {
    let text: String
    let color: Color
    
    init(text: String, color: Color = .red) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color)
            )
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    
    @State private var isAppearing = false
    
    init(title: String, value: String, subtitle: String? = nil, icon: String, color: Color = .accentColor) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        AnimatedCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .scaleEffect(isAppearing ? 1.0 : 0.8)
        .opacity(isAppearing ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: isAppearing)
        .onAppear {
            isAppearing = true
        }
    }
}