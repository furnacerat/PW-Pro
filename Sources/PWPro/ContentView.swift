import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var errorManager = ErrorManager.shared
    @StateObject private var successManager = SuccessManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var selectedTab = 0
    @State private var showingErrorToast = false
    @State private var showingSuccessToast = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if authManager.isTermsAccepted {
                    // Check if onboarding is needed
                    if !onboardingManager.hasCompletedOnboarding {
                        OnboardingView()
                            .environmentObject(authManager)
                            .environmentObject(subscriptionManager)
                    } else {
                        // Enhanced main app with comprehensive error handling and offline support
                        ZStack {
                            VStack(spacing: 0) {
                                // Enhanced offline banner with sync status
                                VStack(spacing: 0) {
                                    OfflineBanner()
                                    
                                    if !networkMonitor.isConnected || (OfflineSyncManager.shared.pendingSyncCount > 0) {
                                        HStack {
                                            SyncStatusView(syncManager: OfflineSyncManager.shared)
                                            
                                            Spacer()
                                            
                                            if OfflineSyncManager.shared.pendingSyncCount > 0 {
                                                Button("Sync Now") {
                                                    OfflineSyncManager.shared.forceSyncNow()
                                                }
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color(.systemGray6))
                                    }
                                }
                                
                                // Enhanced TabView with custom items
                                TabView(selection: $selectedTab) {
                                    DashboardView()
                                        .tabItem {
                                            EnhancedTabItem(
                                                title: "Dashboard",
                                                systemImage: "chart.bar.doc.horizontal",
                                                isSelected: selectedTab == 0
                                            )
                                        }
                                        .tag(0)
                                    
                                    CalendarView()
                                        .tabItem {
                                            EnhancedTabItem(
                                                title: "Schedule",
                                                systemImage: "calendar",
                                                isSelected: selectedTab == 1
                                            )
                                        }
                                        .tag(1)
                                    
                                    EstimatorView()
                                        .tabItem {
                                            EnhancedTabItem(
                                                title: "Estimator",
                                                systemImage: "doc.text.fill",
                                                isSelected: selectedTab == 2
                                            )
                                        }
                                        .tag(2)
                                    
                                    FieldToolsView()
                                        .tabItem {
                                            EnhancedTabItem(
                                                title: "Field Tools",
                                                systemImage: "hammer.fill",
                                                isSelected: selectedTab == 3
                                            )
                                        }
                                        .tag(3)
                                    
                                    BusinessSuiteView()
                                        .tabItem {
                                            EnhancedTabItem(
                                                title: "Business",
                                                systemImage: "briefcase.fill",
                                                isSelected: selectedTab == 4
                                            )
                                        }
                                        .tag(4)
                                }
                                .accentColor(Theme.sky500)
                                .onChange(of: selectedTab) { _, newValue in
                                    HapticManager.selection()
                                    
                                    // Schedule notifications for relevant tab
                                    if newValue == 1 { // Calendar
                                        Task {
                                            await notificationManager.scheduleDailySummary(at: Date())
                                        }
                                    }
                                }
                            }
                            
                            // Floating action button for quick actions
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    FloatingActionButton(icon: "plus") {
                                        // Quick action based on selected tab
                                        handleQuickAction()
                                    }
                                    .padding(.trailing, 20)
                                    .padding(.bottom, 30)
                                }
                            }
                            
                            // Enhanced error handling overlay
                            VStack {
                                if errorManager.showError, let error = errorManager.currentError {
                                    VStack {
                                        Spacer()
                                        ErrorToast(error: error) {
                                            errorManager.dismissError()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 20)
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                    }
                                    .animation(.easeInOut, value: errorManager.showError)
                                }
                                
                                if successManager.showSuccess, let success = successManager.currentSuccess {
                                    VStack {
                                        Spacer()
                                        SuccessToast(message: success) {
                                            successManager.dismissSuccess()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 100)
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                    }
                                    .animation(.easeInOut, value: successManager.showSuccess)
                                }
                            }
                        }
                        .preferredColorScheme(.dark)
                        .environmentObject(authManager)
                        .environmentObject(subscriptionManager)
                        .environmentObject(errorManager)
                        .environmentObject(successManager)
                        .environmentObject(networkMonitor)
                        .sheet(isPresented: $subscriptionManager.showPaywall) {
                            PaywallView()
                                .environmentObject(subscriptionManager)
                        }
                        .onAppear {
                            // Initialize services and notifications
                            Task {
                                await initializeServices()
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                            // Refresh data when app becomes active
                            Task {
                                await refreshData()
                            }
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
                    .environmentObject(errorManager)
            }
        }
        .accentColor(Theme.sky500)
        .task {
            // Request notification permissions on app launch
            if authManager.isAuthenticated && !notificationManager.isAuthorized {
                await notificationManager.requestAuthorization()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleQuickAction() {
        HapticManager.lightImpact()
        
        switch selectedTab {
        case 0: // Dashboard
            // Quick add job
            NotificationCenter.default.post(name: .quickAddJob, object: nil)
            
        case 1: // Calendar
            // Quick schedule job
            NotificationCenter.default.post(name: .quickScheduleJob, object: nil)
            
        case 2: // Estimator
            // Quick create estimate
            NotificationCenter.default.post(name: .quickCreateEstimate, object: nil)
            
        case 3: // Field Tools
            // Quick add expense
            NotificationCenter.default.post(name: .quickAddExpense, object: nil)
            
        case 4: // Business
            // Quick add client
            NotificationCenter.default.post(name: .quickAddClient, object: nil)
            
        default:
            break
        }
    }
    
    private func initializeServices() async {
        do {
            // Initialize service container
            ServiceFactory.initializeServices()
            
            // Initialize offline sync manager
            _ = OfflineSyncManager.shared
            
            // Set up notification delegate
            UNUserNotificationCenter.current().delegate = NotificationDelegate()
            
            // Sync data if online
            if networkMonitor.isConnected {
                await OfflineSyncManager.shared.syncAllData()
            }
            
            // Schedule daily notifications
            await notificationManager.scheduleDailySummary(at: Date().addingTimeInterval(3600)) // 1 hour from now
            
            print("App services initialized successfully")
            
        } catch {
            errorManager.handle(error, context: "App Initialization")
        }
    }
    
    private func refreshData() async {
        do {
            if networkMonitor.isConnected {
                await OfflineSyncManager.shared.syncAllData()
                successManager.showSuccess(title: "Data Updated", message: "Your data has been synced")
            }
        } catch {
            // Don't show error for background refresh failures
            print("Background refresh failed: \(error)")
        }
    }
}

// MARK: - Enhanced Notification Names

extension Notification.Name {
    static let quickAddJob = Notification.Name("quickAddJob")
    static let quickScheduleJob = Notification.Name("quickScheduleJob")
    static let quickCreateEstimate = Notification.Name("quickCreateEstimate")
    static let quickAddExpense = Notification.Name("quickAddExpense")
    static let quickAddClient = Notification.Name("quickAddClient")
}
