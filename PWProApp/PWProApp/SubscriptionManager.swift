import SwiftUI
import RevenueCat

// MARK: - RevenueCat Configuration
enum RevenueCatConfig {
    // RevenueCat API Key - Use appl_ key for production
    static let apiKey = "test_HHoSLZqsOFVbWTArdOZiROcPpYx"
    
    // Entitlement identifier configured in RevenueCat dashboard
    static let premiumEntitlement = "premium"
}

// MARK: - Subscription Tier
enum SubscriptionTier: String, CaseIterable {
    case monthly = "pwpro_monthly"
    case yearly = "pwpro_yearly"
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly (Save 17%)"
        }
    }
    
    var features: [String] {
        return [
            "Unlimited jobs & clients",
            "AI-powered surface detection",
            "AR alignment camera",
            "Smart route optimization",
            "Full chemical inventory",
            "Lead pipeline management",
            "Weather integration",
            "Advanced P&L reporting",
            "Priority support"
        ]
    }
}

// MARK: - Subscription Manager
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isSubscribed = false
    @Published var currentOffering: Offering?
    @Published var purchaseInProgress = false
    @Published var showPaywall = false
    @Published var errorMessage: String?
    
    // Free usage tracking
    private let freeScansKey = "freeScansUsed"
    private let maxFreeScans = 3
    
    @Published var freeScansUsed: Int {
        didSet {
            UserDefaults.standard.set(freeScansUsed, forKey: freeScansKey)
        }
    }
    
    var freeScansRemaining: Int {
        max(0, maxFreeScans - freeScansUsed)
    }
    
    var hasFreeScanAvailable: Bool {
        isSubscribed || freeScansRemaining > 0
    }
    
    // Available packages from RevenueCat
    var availablePackages: [Package] {
        // Return only the primary monthly and annual packages to avoid duplicates
        var packages: [Package] = []
        if let monthly = currentOffering?.monthly {
            packages.append(monthly)
        }
        if let yearly = currentOffering?.annual {
            packages.append(yearly)
        }
        return packages
    }
    
    var monthlyPackage: Package? {
        currentOffering?.monthly
    }
    
    var yearlyPackage: Package? {
        currentOffering?.annual
    }
    
    init() {
        self.freeScansUsed = UserDefaults.standard.integer(forKey: freeScansKey)
    }
    
    // MARK: - RevenueCat Setup
    
    func configure() {
        // Configure RevenueCat
        Purchases.logLevel = .debug // Set to .error for production
        Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)
        
        // Listen for customer info updates
        Purchases.shared.delegate = RevenueCatDelegate.shared
        
        // Fetch initial state
        Task {
            await fetchOfferings()
            await checkSubscriptionStatus()
        }
    }
    
    // MARK: - Offerings
    
    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
        } catch {
            print("❌ Failed to fetch offerings: \(error.localizedDescription)")
            errorMessage = "Failed to load subscription options"
        }
    }
    
    // MARK: - Purchase
    
    func purchase(package: Package) async throws {
        purchaseInProgress = true
        errorMessage = nil
        
        defer { purchaseInProgress = false }
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            
            if !result.userCancelled {
                // Purchase successful
                await checkSubscriptionStatus()
                showPaywall = false
                HapticManager.success()
            }
        } catch {
            print("❌ Purchase failed: \(error.localizedDescription)")
            errorMessage = "Purchase failed. Please try again."
            HapticManager.notification(.error)
            throw error
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await updateSubscriptionStatus(from: customerInfo)
            HapticManager.success()
        } catch {
            print("❌ Restore failed: \(error.localizedDescription)")
            errorMessage = "Failed to restore purchases"
            HapticManager.notification(.error)
        }
    }
    
    // MARK: - Subscription Status
    
    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            await updateSubscriptionStatus(from: customerInfo)
        } catch {
            print("❌ Failed to get customer info: \(error.localizedDescription)")
        }
    }
    
    func updateSubscriptionStatus(from customerInfo: CustomerInfo) async {
        // Check if user has active premium entitlement
        isSubscribed = customerInfo.entitlements[RevenueCatConfig.premiumEntitlement]?.isActive == true
    }
    
    // MARK: - Free Scan Management
    
    /// Use one free scan. Returns true if scan is allowed, false if paywall should show.
    func useFreeScan() -> Bool {
        if isSubscribed {
            return true
        }
        
        if freeScansRemaining > 0 {
            freeScansUsed += 1
            return true
        }
        
        // No more free scans - show paywall
        showPaywall = true
        return false
    }
    
    /// Check if user can scan (without consuming a scan)
    func canScan() -> Bool {
        return isSubscribed || freeScansRemaining > 0
    }
    
    // Paywall triggers
    func requestSubscriptionIfNeeded() {
        if !isSubscribed {
            showPaywall = true
            HapticManager.notification(.warning)
        }
    }
}

// MARK: - RevenueCat Delegate

class RevenueCatDelegate: NSObject, PurchasesDelegate {
    static let shared = RevenueCatDelegate()
    
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            await SubscriptionManager.shared.updateSubscriptionStatus(from: customerInfo)
        }
    }
}
