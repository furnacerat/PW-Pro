import SwiftUI

@main
struct PWProApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    init() {
        // Configure RevenueCat on app launch
        SubscriptionManager.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(subscriptionManager)
                .sheet(isPresented: $subscriptionManager.showPaywall) {
                    PaywallView()
                        .environmentObject(subscriptionManager)
                }
                .background(Theme.slate900)
                #if os(macOS)
                .frame(minWidth: 800, minHeight: 600)
                #endif
        }
    }
}
