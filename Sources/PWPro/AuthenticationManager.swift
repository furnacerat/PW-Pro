import SwiftUI

enum UserRole: String, Codable {
    case admin = "Admin"
    case technician = "Technician"
}

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isTermsAccepted = false
    @Published var currentUserRole: UserRole = .admin // Default for demo
    
    private let termsAcceptedKey = "PWPro_TermsAccepted"
    
    init() {
        self.isTermsAccepted = UserDefaults.standard.bool(forKey: termsAcceptedKey)
    }
    
    func login() {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                self.isAuthenticated = true
            }
        }
    }
    
    func logout() {
        withAnimation {
            self.isAuthenticated = false
            // Note: We don't reset isTermsAccepted here to keep it persistent for the user/device
        }
    }
    
    func acceptTerms() {
        withAnimation {
            self.isTermsAccepted = true
            UserDefaults.standard.set(true, forKey: termsAcceptedKey)
        }
    }
}
