import SwiftUI
import Combine

enum UserRole: String, Codable {
    case admin = "Admin"
    case technician = "Technician"
}

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isTermsAccepted = false
    @Published var currentUserRole: UserRole = .admin // Default for demo
    @Published var error: String?
    @Published var isLoading = false
    
    private let termsAcceptedKey = "PWPro_TermsAccepted"
    private let supabase = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.isTermsAccepted = UserDefaults.standard.bool(forKey: termsAcceptedKey)
        
        // Use Combine to keep isAuthenticated in sync with SupabaseManager
        supabase.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] authenticated in
                self?.isAuthenticated = authenticated
                print("AuthManager: isAuthenticated changed to \(authenticated)")
            }
            .store(in: &cancellables)
    }
    
    func signUp(email: String, password: String) async {
        guard !email.isEmpty && !password.isEmpty else {
            self.error = "Please enter both email and password"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            try await supabase.signUp(email: email, password: password)
            // isAuthenticated is updated via Combine observer
        } catch {
            self.handleError(error, context: "Signup")
        }
        
        isLoading = false
    }
    
    func login(email: String, password: String) async {
        guard !email.isEmpty && !password.isEmpty else {
            self.error = "Please enter both email and password"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            try await supabase.signIn(email: email, password: password)
            // isAuthenticated is updated via Combine observer
        } catch {
            self.handleError(error, context: "Login")
        }
        
        isLoading = false
    }
    
    private func handleError(_ error: Error, context: String) {
        let message = error.localizedDescription
        
        if message.contains("invalid claim") || message.contains("invalid_credentials") {
            self.error = "Invalid email or password. Please check your credentials."
        } else if message.contains("Email not confirmed") {
            self.error = "Please confirm your email address before signing in."
        } else if message.contains("network") {
            self.error = "Network error. Please check your internet connection."
        } else {
            self.error = "\(context) failed: \(message)"
        }
        
        print("\(context) failed: \(message)")
    }
    
    func logout() async {
        do {
            try await supabase.signOut()
            // isAuthenticated is updated via Combine observer
        } catch {
            self.error = error.localizedDescription
            print("Logout failed: \(error)")
        }
    }
    
    /// Developer bypass to allow testing UI without Supabase auth
    func developerBypass() {
        withAnimation {
            self.error = nil // Clear the rate limit error
            self.isAuthenticated = true
            
            // Also update SupabaseManager shared state so Combine doesn't revert it
            SupabaseManager.shared.isAuthenticated = true
            
            print("AuthManager: Developer bypass activated and error cleared")
        }
    }
    
    func acceptTerms() {
        withAnimation {
            self.isTermsAccepted = true
            UserDefaults.standard.set(true, forKey: termsAcceptedKey)
        }
    }
}
