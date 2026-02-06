import SwiftUI
import Foundation

struct Theme {
    // Enhanced Color Palette - Industrial Precision
    static let slate900 = Color(hex: "0F172A")
    static let slate800 = Color(hex: "1E293B")
    static let slate700 = Color(hex: "334155")
    static let slate600 = Color(hex: "475569")
    static let slate500 = Color(hex: "64748B")
    static let slate400 = Color(hex: "94A3B8")
    static let slate300 = Color(hex: "CBD5E1")
    static let slate100 = Color(hex: "F1F5F9")
    static let slate50 = Color(hex: "F8FAFC")
    
    // Primary - Power Blue (more vibrant)
    static let sky700 = Color(hex: "0369A1")
    static let sky500 = Color(hex: "0EA5E9")
    static let sky400 = Color(hex: "38BDF8")
    
    // Accent Colors - Industrial Palette
    static let emerald500 = Color(hex: "10B981")  // Success/Clean
    static let amber500 = Color(hex: "F59E0B")    // Warning
    static let red500 = Color(hex: "EF4444")      // Critical
    static let purple500 = Color(hex: "A855F7")   // Premium
    static let pink500 = Color(hex: "EC4899")     // Accent
    
    // Special Effects
    static let chromeGradient = LinearGradient(
        colors: [Color(hex: "E5E7EB"), Color(hex: "9CA3AF"), Color(hex: "E5E7EB")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Gradients
    static let primaryGradient = LinearGradient(colors: [sky500, sky700], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let glassGradient = LinearGradient(colors: [.white.opacity(0.15), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
    
    // Industrial Typography System
    // Note: Using SF Pro as fallback since custom fonts need to be added to project
    // Bebas Neue = Industrial, commanding headers
    // Work Sans = Professional, clean body text
    // JetBrains Mono = Technical precision for data
    
    static let industrialHeading = Font.system(size: 32, weight: .black, design: .default)
        .fallback(.system(size: 32, weight: .heavy, design: .default))
    
    static let industrialSubheading = Font.system(size: 20, weight: .bold, design: .default)
        .fallback(.system(size: 20, weight: .semibold, design: .default))
    
    static let professionalBody = Font.system(size: 16, weight: .medium, design: .default)
        .fallback(.system(size: 16, weight: .regular, design: .default))
    
    static let dataMonospace = Font.system(size: 14, weight: .semibold, design: .monospaced)
        .fallback(.system(size: 14, weight: .medium, design: .monospaced))
    
    static let labelText = Font.system(size: 11, weight: .bold, design: .default)
        .fallback(.system(size: 11, weight: .semibold, design: .default))
    
    // Legacy fonts for backward compatibility (with Dynamic Type)
    static let headingFont = Font.custom("Poppins-Bold", size: 28, relativeTo: .title).fallback(industrialHeading)
    static let subheadlineFont = Font.custom("Poppins-SemiBold", size: 18, relativeTo: .headline).fallback(industrialSubheading)
    static let bodyFont = Font.custom("OpenSans-Regular", size: 16, relativeTo: .body).fallback(professionalBody)
    static let labelFont = Font.custom("OpenSans-Bold", size: 12, relativeTo: .caption).fallback(labelText)
    
    // Glass Constants
    static let glassBlur: CGFloat = 20
    static let glassOpacity: Double = 0.15
}

// MARK: - Custom Button Styles

/// Pressable button style with scale animation, spring effect, and haptic feedback
struct PressableButtonStyle: ButtonStyle {
    var enableHaptic: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && enableHaptic {
                    #if os(iOS)
                    HapticManager.light()
                    #endif
                }
            }
    }
}

/// Pressable card modifier for interactive cards
struct PressableCardModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 1.02 : 1.0)
            .shadow(
                color: Theme.sky500.opacity(isPressed ? 0.3 : 0.1),
                radius: isPressed ? 20 : 10,
                y: isPressed ? 8 : 4
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .background(
                Button(action: {}) {
                    Color.clear
                }
                .buttonStyle(PressStyle(isPressed: $isPressed))
            )
    }
}

private struct PressStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

extension View {
    /// Apply pressable card effect with scale and shadow animation
    func pressableCard() -> some View {
        self.modifier(PressableCardModifier())
    }
}


extension Font {
    func fallback(_ font: Font) -> Font {
        self
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
