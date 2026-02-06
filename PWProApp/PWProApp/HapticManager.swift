import SwiftUI

#if os(iOS)
import UIKit

/// Centralized haptic feedback manager for consistent tactile responses across the app
struct HapticManager {
    
    // MARK: - Impact Feedback
    
    /// Triggers impact feedback for button taps, card selections, etc.
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Light impact - for subtle interactions like toggles
    static func light() {
        impact(.light)
    }
    
    /// Medium impact - for standard button taps
    static func medium() {
        impact(.medium)
    }
    
    /// Heavy impact - for significant actions like confirmations
    static func heavy() {
        impact(.heavy)
    }
    
    /// Soft impact - for gentle feedback
    static func soft() {
        impact(.soft)
    }
    
    /// Rigid impact - for firm feedback
    static func rigid() {
        impact(.rigid)
    }
    
    // MARK: - Notification Feedback
    
    /// Triggers notification feedback for status changes
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    /// Success notification - for completed actions
    static func success() {
        notification(.success)
    }
    
    /// Warning notification - for alerts or caution states
    static func warning() {
        notification(.warning)
    }
    
    /// Error notification - for failed actions
    static func error() {
        notification(.error)
    }
    
    // MARK: - Selection Feedback
    
    /// Selection feedback - for picker changes, segment controls
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

#else
// macOS stub - no haptics
struct HapticManager {
    static func impact(_ style: Any? = nil) {}
    static func light() {}
    static func medium() {}
    static func heavy() {}
    static func soft() {}
    static func rigid() {}
    static func notification(_ type: Any? = nil) {}
    static func success() {}
    static func warning() {}
    static func error() {}
    static func selection() {}
}
#endif

// MARK: - View Modifiers for Easy Integration

struct HapticButtonStyle: ButtonStyle {
    var style: UIImpactFeedbackGenerator.FeedbackStyle = .medium
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    #if os(iOS)
                    HapticManager.impact(style)
                    #endif
                }
            }
    }
}

extension View {
    /// Adds haptic feedback on tap
    func hapticOnTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                #if os(iOS)
                HapticManager.impact(style)
                #endif
            }
        )
    }
}
