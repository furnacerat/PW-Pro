import Foundation
import SwiftUI

@MainActor
class ReputationManager: ObservableObject {
    static let shared = ReputationManager()
    
    private let invoiceManager = InvoiceManager.shared
    
    // MARK: - Review Request Logic
    
    func generateReviewMessage(clientName: String, platform: ReviewPlatform) -> String {
        let settings = invoiceManager.businessSettings
        let template = settings.reviewRequestTemplate
        let link = platform == .google ? settings.googleReviewLink : settings.facebookReviewLink
        
        // Simple template replacement
        let message = template
            .replacingOccurrences(of: "{ClientName}", with: clientName)
            .replacingOccurrences(of: "{BusinessName}", with: settings.businessName)
            .replacingOccurrences(of: "{Link}", with: link)
            
        return message
    }
    
    func requestReview(clientName: String, platform: ReviewPlatform) {
        let message = generateReviewMessage(clientName: clientName, platform: platform)
        
        #if os(iOS)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            let activityVC = UIActivityViewController(activityItems: [message], applicationActivities: nil)
            rootViewController.present(activityVC, animated: true)
        }
        #elseif os(macOS)
        let picker = NSSharingServicePicker(items: [message])
        picker.show(relativeTo: .zero, of: NSApp.keyWindow?.contentView ?? NSView(), preferredEdge: .minY)
        #endif
    }
    
    enum ReviewPlatform: String, CaseIterable, Identifiable {
        case google = "Google"
        case facebook = "Facebook"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .google: return "globe"
            case .facebook: return "hand.thumbsup.fill"
            }
        }
    }
}
