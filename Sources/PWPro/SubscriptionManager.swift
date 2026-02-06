import SwiftUI
import StoreKit

// Single tier subscription
enum SubscriptionTier: String, CaseIterable {
    case pro = "com.haroldfoster.pwproapp.pro"
    
    var displayName: String {
        return "PWPro Premium"
    }
    
    var price: String {
        return "$74.95"
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

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var isSubscribed = false
    @Published var availableProducts: [Product] = []
    @Published var purchaseInProgress = false
    @Published var showPaywall = false
    
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
    
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        self.freeScansUsed = UserDefaults.standard.integer(forKey: freeScansKey)
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: [SubscriptionTier.pro.rawValue])
            availableProducts = products
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try await checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            showPaywall = false
            HapticManager.success()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }
    
    func updateSubscriptionStatus() async {
        var hasValidSubscription = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try await checkVerified(result)
                
                if transaction.productID == SubscriptionTier.pro.rawValue {
                    hasValidSubscription = true
                    break
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        isSubscribed = hasValidSubscription
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    nonisolated func checkVerified<T>(_ result: VerificationResult<T>) async throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
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

enum StoreError: Error {
    case failedVerification
}
