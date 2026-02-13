import UIKit

enum ShowcaseLayout: String, CaseIterable, Identifiable {
    case splitVertical = "Side by Side"
    case splitHorizontal = "Top / Bottom"
    
    var id: String { rawValue }
}

struct ShowcaseGenerator {
    
    static func generateShowcase(before: UIImage, after: UIImage, layout: ShowcaseLayout, businessSettings: BusinessSettings) -> UIImage? {
        let size = CGSize(width: 1200, height: 1200) // Standard high-res square for social
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Fill background
            UIColor.black.setFill()
            context.cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Draw Images based on layout
            drawImages(context: context.cgContext, before: before, after: after, layout: layout, size: size)
            
            // Draw Divider
            drawDivider(context: context.cgContext, layout: layout, size: size)
            
            // Draw Labels (Before/After)
            drawLabels(context: context.cgContext, layout: layout, size: size)
            
            // Draw Branding (Logo & Phone)
            drawBranding(context: context.cgContext, size: size, settings: businessSettings)
        }
    }
    
    private static func drawImages(context: CGContext, before: UIImage, after: UIImage, layout: ShowcaseLayout, size: CGSize) {
        let rect1: CGRect
        let rect2: CGRect
        
        switch layout {
        case .splitVertical:
            rect1 = CGRect(x: 0, y: 0, width: size.width / 2, height: size.height)
            rect2 = CGRect(x: size.width / 2, y: 0, width: size.width / 2, height: size.height)
        case .splitHorizontal:
            rect1 = CGRect(x: 0, y: 0, width: size.width, height: size.height / 2)
            rect2 = CGRect(x: 0, y: size.height / 2, width: size.width, height: size.height / 2)
        }
        
        before.draw(in: rect1)
        after.draw(in: rect2)
    }
    
    private static func drawDivider(context: CGContext, layout: ShowcaseLayout, size: CGSize) {
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(4)
        
        context.beginPath()
        switch layout {
        case .splitVertical:
            context.move(to: CGPoint(x: size.width / 2, y: 0))
            context.addLine(to: CGPoint(x: size.width / 2, y: size.height))
        case .splitHorizontal:
            context.move(to: CGPoint(x: 0, y: size.height / 2))
            context.addLine(to: CGPoint(x: size.width, y: size.height / 2))
        }
        context.strokePath()
    }
    
    private static func drawLabels(context: CGContext, layout: ShowcaseLayout, size: CGSize) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 40, weight: .bold),
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0 // Negative for fill + stroke
        ]
        
        let beforeText = NSAttributedString(string: "BEFORE", attributes: attributes)
        let afterText = NSAttributedString(string: "AFTER", attributes: attributes)
        
        let padding: CGFloat = 20
        
        let p1: CGPoint
        let p2: CGPoint
        
        switch layout {
        case .splitVertical:
            p1 = CGPoint(x: padding, y: padding)
            p2 = CGPoint(x: (size.width / 2) + padding, y: padding)
        case .splitHorizontal:
            p1 = CGPoint(x: padding, y: padding)
            p2 = CGPoint(x: padding, y: (size.height / 2) + padding)
        }
        
        beforeText.draw(at: p1)
        afterText.draw(at: p2)
    }
    
    private static func drawBranding(context: CGContext, size: CGSize, settings: BusinessSettings) {
        // Footer Bar
        let footerHeight: CGFloat = 100
        let footerRect = CGRect(x: 0, y: size.height - footerHeight, width: size.width, height: footerHeight)
        
        context.setFillColor(UIColor.black.withAlphaComponent(0.7).cgColor)
        context.fill(footerRect)
        
        // Logo
        if let logoData = settings.logoData, let logo = UIImage(data: logoData) {
            let logoSize: CGFloat = 80
            let logoRect = CGRect(x: 20, y: size.height - 90, width: logoSize, height: logoSize)
            logo.draw(in: logoRect)
        }
        
        // Business Info
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        let phoneAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .medium),
            .foregroundColor: UIColor(red: 0/255, green: 200/255, blue: 255/255, alpha: 1.0) // Sky blue
        ]
        
        let nameText = NSAttributedString(string: settings.businessName, attributes: nameAttrs)
        let phoneText = NSAttributedString(string: settings.businessPhone, attributes: phoneAttrs)
        
        let textX: CGFloat = 120 // Spacing after logo
        nameText.draw(at: CGPoint(x: textX, y: size.height - 85))
        phoneText.draw(at: CGPoint(x: textX, y: size.height - 45))
    }
}
