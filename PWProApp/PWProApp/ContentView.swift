import SwiftUI

extension Notification.Name {
    static let switchToFieldTools = Notification.Name("switchToFieldTools")
}

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var selectedTab = 0
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
            
            Group {
                if authManager.isAuthenticated {
                if authManager.isTermsAccepted {
                    // Check if onboarding is needed
                    if !onboardingManager.hasCompletedOnboarding {
                        OnboardingView()
                            .environmentObject(authManager)
                            .environmentObject(subscriptionManager)
                    } else {
                        // Main app with offline awareness
                        VStack(spacing: 0) {
                            OfflineBanner()
                            
                            TabView(selection: $selectedTab) {
                                DashboardView()
                                    .tabItem {
                                        Label("Dashboard", systemImage: "chart.bar.doc.horizontal")
                                    }
                                    .tag(0)
                                
                                CalendarView()
                                    .tabItem {
                                        Label("Schedule", systemImage: "calendar")
                                    }
                                    .tag(1)
                                    
                                EstimatorView()
                                    .tabItem {
                                        Label("Estimator", systemImage: "doc.text.fill")
                                    }
                                    .tag(2)
                                    
                                FieldToolsView()
                                    .tabItem {
                                        Label("Field Tools", systemImage: "hammer.fill")
                                    }
                                    .tag(4)
                                
                                BusinessSuiteView()
                                    .tabItem {
                                        Label("Business", systemImage: "briefcase.fill")
                                    }
                                    .tag(5)
                            }
                            .onChange(of: selectedTab) { _, _ in
                                HapticManager.selection()
                            }
                        }
                        .accentColor(Theme.sky500)
                        .preferredColorScheme(.dark)
                        .environmentObject(authManager)
                        .environmentObject(subscriptionManager)
                        .sheet(isPresented: $subscriptionManager.showPaywall) {
                            PaywallView()
                                .environmentObject(subscriptionManager)
                        }
                    }
                } else {
                    TermsAndConditionsView(isMandatory: true)
                        .environmentObject(authManager)
                        .transition(.move(edge: .bottom))
                }
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .accentColor(Theme.sky500)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showSplash = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToFieldTools)) { _ in
            withAnimation { selectedTab = 4 }
        }
    }
}
}
