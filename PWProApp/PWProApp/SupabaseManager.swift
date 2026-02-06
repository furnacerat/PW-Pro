
import Foundation
import Supabase

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {
        // Load configuration from Security Service
        let configService = ConfigurationService.shared
        
        // Initialize Supabase client with config
        client = SupabaseClient(
            supabaseURL: configService.supabaseURL,
            supabaseKey: configService.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
        
        Task {
            await checkSession()
        }
    }
    
    // MARK: - Authentication
    
    func checkSession() async {
        do {
            let session = try await client.auth.session
            
            if session.isExpired {
                print("Stored session is expired.")
                isAuthenticated = false
                currentUser = nil
                return
            }
            
            currentUser = session.user
            isAuthenticated = true
            print("Session found for user: \(currentUser?.email ?? "unknown")")
        } catch {
            print("No active session: \(error.localizedDescription)")
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    func signUp(email: String, password: String) async throws {
        let response = try await client.auth.signUp(email: email, password: password)
        currentUser = response.user
        isAuthenticated = true
    }
    
    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        currentUser = session.user
        isAuthenticated = true
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }
}
