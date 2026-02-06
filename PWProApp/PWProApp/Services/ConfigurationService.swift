
import Foundation

class ConfigurationService {
    static let shared = ConfigurationService()
    
    private let keychain = KeychainHelper.shared
    private let serviceName = "com.haroldfoster.pressurewashingpro.keys"
    
    private enum Keys {
        static let supabaseURL = "SUPABASE_URL"
        static let supabaseAnonKey = "SUPABASE_ANON_KEY"
        static let geminiAPIKey = "GEMINI_API_KEY"
    }
    
    var supabaseURL: URL {
        guard let string = get(key: Keys.supabaseURL), let url = URL(string: string) else {
            fatalError("Supabase URL not found. Please ensure it is in Config.plist or Keychain.")
        }
        return url
    }
    
    var supabaseAnonKey: String {
        guard let key = get(key: Keys.supabaseAnonKey) else {
            fatalError("Supabase Anon Key not found. Please ensure it is in Config.plist or Keychain.")
        }
        return key
    }
    
    var geminiKey: String? {
        return get(key: Keys.geminiAPIKey)
    }
    
    private init() {
        // Perform initial migration if needed
        migrationCheck()
    }
    
    private func get(key: String) -> String? {
        // 1. Try Keychain
        if let value = keychain.readString(service: serviceName, account: key) {
           // print("ConfigurationService: Loaded \(key) from Keychain") // Security: Don't log values
            return value
        }
        
        // 2. Try Plist (Bootstrap)
        if let value = loadFromPlist(key: key) {
            print("ConfigurationService: Bootstrapping \(key) from Plist to Keychain")
            // 3. Save to Keychain for next time
            keychain.save(value, service: serviceName, account: key)
            return value
        }
        
        return nil
    }
    
    private func loadFromPlist(key: String) -> String? {
        let names = ["Config", "Config2"]
        for name in names {
            if let path = Bundle.main.path(forResource: name, ofType: "plist"),
               let config = NSDictionary(contentsOfFile: path),
               let value = config[key] as? String {
                return value
            }
        }
        return nil
    }
    
    private func migrationCheck() {
        // Trigger lazy loading of critical keys to ensure they migrate immediately on startup
        _ = try? get(key: Keys.supabaseURL) // triggers get logic
        _ = try? get(key: Keys.supabaseAnonKey)
        _ = try? get(key: Keys.geminiAPIKey)
    }
}
