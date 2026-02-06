
import Foundation
import Supabase

@MainActor
class AuthService: ObservableObject {
    private let client: SupabaseClient
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    init(client: SupabaseClient) {
        self.client = client
        Task {
            await checkSession()
        }
    }
    
    func checkSession() async {
        do {
            let session = try await client.auth.session
            if session.isExpired {
                print("AuthService: Stored session is expired.")
                isAuthenticated = false
                currentUser = nil
                return
            }
            currentUser = session.user
            isAuthenticated = true
            print("AuthService: Session found for user: \(currentUser?.email ?? "unknown")")
        } catch {
            print("AuthService: No active session: \(error.localizedDescription)")
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
