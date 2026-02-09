import SwiftUI
import Combine
import Network

enum UserRole: String, Codable, CaseIterable {
    case admin = "admin"
    case owner = "owner"
    case technician = "technician"
    
    var displayName: String {
        switch self {
        case .admin: return "Admin"
        case .owner: return "Owner"
        case .technician: return "Technician"
        }
    }
}

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isTermsAccepted = false
    @Published var currentUserRole: UserRole = .owner
    @Published var currentUserProfile: UserProfile?
    @Published var error: String?
    @Published var isLoading = false
    @Published var isOfflineMode = false
    
    private let termsAcceptedKey = "PWPro_TermsAccepted"
    private let userRoleKey = "PWPro_UserRole"
    private let supabase = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var networkMonitor = NetworkMonitor.shared
    
    init() {
        self.isTermsAccepted = UserDefaults.standard.bool(forKey: termsAcceptedKey)
        
        // Load saved user role
        if let roleString = UserDefaults.standard.string(forKey: userRoleKey),
           let role = UserRole(rawValue: roleString) {
            self.currentUserRole = role
        }
        
        // Subscribe to Supabase authentication state
        supabase.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] authenticated in
                self?.isAuthenticated = authenticated
                if authenticated {
                    Task { @MainActor in
                        await self?.loadUserProfile()
                    }
                } else {
                    self?.currentUserProfile = nil
                }
                print("AuthManager: Authentication state changed to \(authenticated)")
            }
            .store(in: &cancellables)
        
        // Subscribe to network monitoring
        networkMonitor.$isConnected
            .receive(on: RunLoop.main)
            .sink { [weak self] connected in
                self?.isOfflineMode = !connected
                if !connected && self?.isAuthenticated == true {
                    print("AuthManager: Network disconnected, enabling offline mode")
                }
            }
            .store(in: &cancellables)
        
        // Validate configuration on init
        validateConfiguration()
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, fullName: String? = nil) async {
        guard validateInputs(email: email, password: password) else { return }
        
        isLoading = true
        error = nil
        
        do {
            try await supabase.signUp(email: email, password: password, fullName: fullName)
            // isAuthenticated is updated via Combine observer
            await logSecurityEvent("user_signup", email: email)
        } catch {
            self.handleError(error, context: "Signup")
            await logSecurityEvent("signup_failed", email: email, error: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func login(email: String, password: String) async {
        guard validateInputs(email: email, password: password) else { return }
        
        isLoading = true
        error = nil
        
        do {
            try await supabase.signIn(email: email, password: password)
            // isAuthenticated is updated via Combine observer
            await logSecurityEvent("user_login", email: email)
        } catch {
            self.handleError(error, context: "Login")
            await logSecurityEvent("login_failed", email: email, error: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func logout() async {
        isLoading = true
        error = nil
        
        do {
            let email = supabase.currentUser?.email
            try await supabase.signOut()
            // isAuthenticated is updated via Combine observer
            await logSecurityEvent("user_logout", email: email)
        } catch {
            self.error = error.localizedDescription
            print("Logout failed: \(error)")
            await logSecurityEvent("logout_failed", email: supabase.currentUser?.email, error: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func resetPassword(email: String) async {
        guard validateEmail(email) else { return }
        
        isLoading = true
        error = nil
        
        do {
            try await supabase.resetPassword(email: email)
            await logSecurityEvent("password_reset", email: email)
        } catch {
            self.handleError(error, context: "Password Reset")
            await logSecurityEvent("password_reset_failed", email: email, error: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    // MARK: - User Profile Management
    
    private func loadUserProfile() async {
        do {
            let profile = try await supabase.getCurrentUserProfile()
            self.currentUserProfile = profile
            
            // Update user role from profile if available
            if let roleString = profile?.role,
               let role = UserRole(rawValue: roleString) {
                self.currentUserRole = role
                UserDefaults.standard.set(roleString, forKey: userRoleKey)
            }
        } catch {
            print("Failed to load user profile: \(error)")
            await logSecurityEvent("profile_load_failed", error: error.localizedDescription)
        }
    }
    
    func updateUserProfile(_ updates: UserProfile) async {
        isLoading = true
        error = nil
        
        do {
            let updated = try await supabase.updateUserProfile(updates)
            self.currentUserProfile = updated
            await logSecurityEvent("profile_updated", userId: updates.id.uuidString)
        } catch {
            self.handleError(error, context: "Profile Update")
            await logSecurityEvent("profile_update_failed", userId: updates.id.uuidString, error: error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func updateUserRole(_ role: UserRole) {
        self.currentUserRole = role
        UserDefaults.standard.set(role.rawValue, forKey: userRoleKey)
        Task {
            await logSecurityEvent("role_updated", role: role.rawValue)
        }
    }
    
    // MARK: - Input Validation (Enhanced Security)
    
    private func validateInputs(email: String, password: String) -> Bool {
        guard validateEmail(email) else { return false }
        guard validatePassword(password) else { return false }
        return true
    }
    
    private func validateEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            self.error = "Please enter a valid email address."
            return false
        }
        
        return true
    }
    
    private func validatePassword(_ password: String) -> Bool {
        // Enhanced password requirements
        if password.count < 8 {
            self.error = "Password must be at least 8 characters long."
            return false
        }
        
        // Check for at least one uppercase letter
        if password.rangeOfCharacter(from: .uppercaseLetters) == nil {
            self.error = "Password must contain at least one uppercase letter."
            return false
        }
        
        // Check for at least one lowercase letter
        if password.rangeOfCharacter(from: .lowercaseLetters) == nil {
            self.error = "Password must contain at least one lowercase letter."
            return false
        }
        
        // Check for at least one digit
        if password.rangeOfCharacter(from: .decimalDigits) == nil {
            self.error = "Password must contain at least one number."
            return false
        }
        
        // Check for special characters (recommended)
        let specialCharRegex = #"^(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]).*$"#
        if !NSPredicate(format: "SELF MATCHES %@", specialCharRegex).evaluate(with: password) {
            // Warning, not error
            print("Security Warning: Password should contain at least one special character for better security.")
        }
        
        return true
    }
    
    // MARK: - Enhanced Error Handling
    
    private func handleError(_ error: Error, context: String) {
        let message = error.localizedDescription
        
        // Account enumeration protection - generic messages
        if message.contains("invalid_claim") || message.contains("invalid_credentials") || message.contains("Invalid login credentials") {
            self.error = "Invalid email or password. Please check your credentials."
        } else if message.contains("Email not confirmed") {
            self.error = "Please confirm your email address before signing in."
        } else if message.contains("user_already_exists") {
            self.error = "An account with this email already exists. Try signing in instead."
        } else if message.contains("signup_disabled") {
            self.error = "User registration is currently disabled. Please contact support."
        } else if message.contains("network") || message.contains("offline") {
            self.error = "Network error. Please check your internet connection."
            isOfflineMode = true
        } else if message.contains("too_many_requests") || message.contains("rate_limit") {
            self.error = "Too many requests. Please wait a moment and try again."
        } else if message.contains("token_expired") {
            self.error = "Your session has expired. Please sign in again."
        } else {
            self.error = "\(context) failed: \(message)"
        }
        
        print("\(context) failed: \(message)")
    }
    
    // MARK: - Security Configuration
    
    private func validateConfiguration() {
        let config = ConfigurationService.shared
        let issues = config.validateConfiguration()
        
        if !issues.isEmpty {
            print("🚨 SECURITY CONFIGURATION ISSUES FOUND:")
            for issue in issues {
                print("  - \(issue)")
            }
            
            if config.isProduction {
                fatalError("Production deployment has security configuration issues. Address before continuing.")
            }
        } else {
            print("✅ Security configuration validated successfully")
        }
        
        #if DEBUG
        config.printConfigurationSummary()
        #endif
    }
    
    // MARK: - Security Logging
    
    private func logSecurityEvent(_ event: String, email: String? = nil, userId: String? = nil, error: String? = nil) async {
        guard ConfigurationService.shared.isProduction else { return }
        
        var eventData: [String: Any] = [
            "event": event,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "user_agent": "PWPro_iOS"
        ]
        
        if let email = email {
            eventData["email_hash"] = sha256(email)
        }
        
        if let userId = userId {
            eventData["user_id"] = userId
        }
        
        if let error = error {
            eventData["error"] = error
        }
        
        // In production, send to security monitoring service
        print("Security Event: \(eventData)")
        // TODO: Integrate with security monitoring service (Sentry, custom endpoint, etc.)
    }
    
    // MARK: - Terms & Conditions
    
    func acceptTerms() {
        withAnimation {
            self.isTermsAccepted = true
            UserDefaults.standard.set(true, forKey: termsAcceptedKey)
            Task {
                await logSecurityEvent("terms_accepted")
            }
        }
    }
    
    func declineTerms() {
        withAnimation {
            self.isTermsAccepted = false
            UserDefaults.standard.set(false, forKey: termsAcceptedKey)
            Task {
                await logSecurityEvent("terms_declined")
            }
        }
    }
    
    // MARK: - Helper Properties
    
    var currentUserEmail: String? {
        return supabase.currentUser?.email
    }
    
    var currentUserID: String? {
        return supabase.currentUser?.id.uuidString
    }
    
    var canAccessBusinessFeatures: Bool {
        return currentUserRole == .owner || currentUserRole == .admin
    }
    
    var canManageTeam: Bool {
        return currentUserRole == .admin || currentUserRole == .owner
    }
    
    var isTechnician: Bool {
        return currentUserRole == .technician
    }
    
    var sessionTimeout: TimeInterval {
        return 24 * 60 * 60 // 24 hours
    }
    
    // MARK: - Production Security Check
    
    func isSessionExpired() -> Bool {
        guard let lastActivity = UserDefaults.standard.object(forKey: "lastActivity") as? Date else {
            return false
        }
        
        return Date().timeIntervalSince(lastActivity) > sessionTimeout
    }
    
    func updateLastActivity() {
        UserDefaults.standard.set(Date(), forKey: "lastActivity")
    }
}

// MARK: - Security Utilities

import CryptoKit

private func sha256(_ input: String) -> String {
    let data = Data(input.utf8)
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}