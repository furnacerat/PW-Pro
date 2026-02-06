import SwiftUI

/// Manages onboarding state and progress
@MainActor
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    private let hasSeenWalkthroughKey = "hasSeenWalkthrough"
    private let onboardingStepKey = "currentOnboardingStep"
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: hasCompletedOnboardingKey)
        }
    }
    
    @Published var hasSeenWalkthrough: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenWalkthrough, forKey: hasSeenWalkthroughKey)
        }
    }
    
    @Published var currentStep: Int {
        didSet {
            UserDefaults.standard.set(currentStep, forKey: onboardingStepKey)
        }
    }
    
    /// Business name - synced with InvoiceManager.shared.businessSettings
    var businessName: String {
        get {
            InvoiceManager.shared.businessSettings.businessName
        }
        set {
            InvoiceManager.shared.businessSettings.businessName = newValue
            objectWillChange.send()
        }
    }
    
    // Onboarding checklist items
    @Published var hasAddedBusinessName: Bool = false
    @Published var hasCreatedFirstClient: Bool = false
    @Published var hasBookedFirstJob: Bool = false
    
    var completionPercentage: Double {
        var completed = 0
        if hasAddedBusinessName { completed += 1 }
        if hasCreatedFirstClient { completed += 1 }
        if hasBookedFirstJob { completed += 1 }
        return Double(completed) / 3.0
    }
    
    var allStepsCompleted: Bool {
        hasAddedBusinessName && hasCreatedFirstClient && hasBookedFirstJob
    }
    
    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
        self.hasSeenWalkthrough = UserDefaults.standard.bool(forKey: hasSeenWalkthroughKey)
        self.currentStep = UserDefaults.standard.integer(forKey: onboardingStepKey)
        
        // Check if business name already exists in InvoiceManager
        self.hasAddedBusinessName = !InvoiceManager.shared.businessSettings.businessName.isEmpty
        
        // Check if user has clients/jobs to update state
        checkExistingData()
    }
    
    func checkExistingData() {
        // Check if user already has clients
        hasCreatedFirstClient = !ClientManager.shared.clients.isEmpty
        
        // Check if user already has jobs
        hasBookedFirstJob = !SchedulingManager.shared.jobs.isEmpty
        
        // Update business name status from InvoiceManager's businessSettings
        hasAddedBusinessName = !InvoiceManager.shared.businessSettings.businessName.isEmpty
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        currentStep = 0
        HapticManager.success()
    }
    
    func skipOnboarding() {
        hasCompletedOnboarding = true
        hasSeenWalkthrough = true
        currentStep = 0
    }
    
    func markWalkthroughComplete() {
        hasSeenWalkthrough = true
        HapticManager.success()
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentStep = 0
        hasAddedBusinessName = false
        hasCreatedFirstClient = false
        hasBookedFirstJob = false
    }
    
    func saveBusinessName(_ name: String) {
        // This sets it in InvoiceManager.shared.businessSettings.businessName
        businessName = name
        hasAddedBusinessName = true
        HapticManager.success()
    }
    
    func markClientCreated() {
        hasCreatedFirstClient = true
        HapticManager.success()
    }
    
    func markJobBooked() {
        hasBookedFirstJob = true
        HapticManager.success()
    }
}
