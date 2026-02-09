import Foundation

class ConfigurationService {
    static let shared = ConfigurationService()
    
    private let keychain = KeychainHelper.shared
    private let serviceName = "com.agentic.pressurewashingpro.keys"
    
    private enum Keys {
        static let supabaseURL = "SUPABASE_URL"
        static let supabaseAnonKey = "SUPABASE_ANON_KEY"
        static let geminiAPIKey = "GEMINI_API_KEY"
        static let openWeatherAPIKey = "OPENWEATHER_API_KEY"
        static let revenueCatPublicKey = "REVENUECAT_PUBLIC_KEY"
        static let appEnvironment = "APP_ENVIRONMENT"
        static let debugMode = "DEBUG_MODE"
        static let logLevel = "LOG_LEVEL"
        static let enableCrashReporting = "ENABLE_CRASH_REPORTING"
        static let enableAnalytics = "ENABLE_ANALYTICS"
    }
    
    // MARK: - Configuration Properties
    
    var supabaseURL: URL {
        guard let string = get(key: Keys.supabaseURL), let url = URL(string: string) else {
            fatalError("Supabase URL not found. Please ensure Config.plist contains SUPABASE_URL")
        }
        return url
    }
    
    var supabaseAnonKey: String {
        guard let key = get(key: Keys.supabaseAnonKey) else {
            fatalError("Supabase Anon Key not found. Please ensure Config.plist contains SUPABASE_ANON_KEY")
        }
        return key
    }
    
    var geminiKey: String? {
        return get(key: Keys.geminiAPIKey)
    }
    
    var openWeatherKey: String? {
        return get(key: Keys.openWeatherAPIKey)
    }
    
    var revenueCatKey: String? {
        return get(key: Keys.revenueCatPublicKey)
    }
    
    var appEnvironment: String {
        return get(key: Keys.appEnvironment) ?? "production"
    }
    
    var isProduction: Bool {
        return appEnvironment.lowercased() == "production"
    }
    
    var isDevelopment: Bool {
        return appEnvironment.lowercased() == "development" || debugMode
    }
    
    var debugMode: Bool {
        return get(key: Keys.debugMode) == "true"
    }
    
    var logLevel: String {
        return get(key: Keys.logLevel) ?? (debugMode ? "debug" : "error")
    }
    
    var crashReportingEnabled: Bool {
        return get(key: Keys.enableCrashReporting) == "true"
    }
    
    var analyticsEnabled: Bool {
        return get(key: Keys.enableAnalytics) == "true"
    }
    
    // MARK: - Initialization
    
    private init() {
        migrationCheck()
    }
    
    private func get(key: String) -> String? {
        // Try Keychain first (most secure)
        if let value = keychain.readString(service: serviceName, account: key) {
            #if DEBUG
            print("ConfigurationService: Loaded \(key) from Keychain")
            #endif
            return value
        }
        
        // Fallback to plist (initial bootstrap)
        if let value = loadFromPlist(key: key) {
            print("ConfigurationService: Bootstrapping \(key) from Plist to Keychain")
            keychain.save(value, service: serviceName, account: key)
            return value
        }
        
        return nil
    }
    
    private func loadFromPlist(key: String) -> String? {
        let plistNames = ["Config.plist", "Config.dev.plist"]
        
        for plistName in plistNames {
            if let path = Bundle.main.path(forResource: plistName.replacingOccurrences(of: ".plist", with: ""), ofType: "plist"),
               let config = NSDictionary(contentsOfFile: path),
               let value = config[key] as? String {
                #if DEBUG
                print("ConfigurationService: Found \(key) in \(plistName)")
                #endif
                return value
            }
        }
        
        return nil
    }
    
    private func migrationCheck() {
        // Ensure all critical keys are available and migrated to keychain
        let criticalKeys = [Keys.supabaseURL, Keys.supabaseAnonKey, Keys.geminiAPIKey]
        
        for key in criticalKeys {
            _ = get(key: key)
        }
    }
    
    // MARK: - Public Update Methods (for development/admin use only)
    
    func updateSupabaseURL(_ url: String) {
        #if DEBUG
        keychain.save(url, service: serviceName, account: Keys.supabaseURL)
        print("ConfigurationService: Updated Supabase URL")
        #else
        print("ConfigurationService: Cannot update Supabase URL in production")
        #endif
    }
    
    func updateSupabaseAnonKey(_ key: String) {
        #if DEBUG
        keychain.save(key, service: serviceName, account: Keys.supabaseAnonKey)
        print("ConfigurationService: Updated Supabase Anon Key")
        #else
        print("ConfigurationService: Cannot update Supabase Anon Key in production")
        #endif
    }
    
    func updateGeminiAPIKey(_ key: String) {
        #if DEBUG
        keychain.save(key, service: serviceName, account: Keys.geminiAPIKey)
        print("ConfigurationService: Updated Gemini API Key")
        #else
        print("ConfigurationService: Cannot update Gemini API Key in production")
        #endif
    }
    
    func updateOpenWeatherKey(_ key: String) {
        #if DEBUG
        keychain.save(key, service: serviceName, account: Keys.openWeatherAPIKey)
        print("ConfigurationService: Updated OpenWeather API Key")
        #else
        print("ConfigurationService: Cannot update OpenWeather API Key in production")
        #endif
    }
    
    // MARK: - Security Validation
    
    func validateConfiguration() -> [String] {
        var issues: [String] = []
        
        // Check required Supabase configuration
        if get(key: Keys.supabaseURL) == nil {
            issues.append("Supabase URL is missing")
        }
        
        if get(key: Keys.supabaseAnonKey) == nil {
            issues.append("Supabase Anon Key is missing")
        }
        
        // Check for hardcoded service role keys (security risk)
        if get(key: "SUPABASE_SERVICE_ROLE_KEY") != nil {
            issues.append("SERVICE ROLE KEY FOUND IN CLIENT CONFIGURATION - SECURITY RISK")
        }
        
        // Check environment consistency
        if debugMode && isProduction {
            issues.append("Debug mode enabled in production environment")
        }
        
        return issues
    }
    
    // MARK: - Diagnostics
    
    func printConfigurationSummary() {
        #if DEBUG
        print("=== PW Pro Configuration Summary ===")
        print("Environment: \(appEnvironment)")
        print("Debug Mode: \(debugMode)")
        print("Production Build: \(!isDevelopment)")
        print("Log Level: \(logLevel)")
        print("Crash Reporting: \(crashReportingEnabled)")
        print("Analytics: \(analyticsEnabled)")
        print("Supabase URL: ✅ Configured")
        print("Supabase Anon Key: ✅ Configured")
        print("Gemini API: \(geminiKey != nil ? "✅ Configured" : "❌ Missing")")
        print("OpenWeather API: \(openWeatherKey != nil ? "✅ Configured" : "❌ Missing")")
        print("=====================================")
        #endif
    }
}

// MARK: - Enhanced Keychain Helper

import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}
    
    func save(_ data: String, service: String, account: String) {
        let data = data.data(using: .utf8)!
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ] as CFDictionary
        
        // Delete existing item first
        SecItemDelete(query)
        
        // Add new item
        let status = SecItemAdd(query, nil)
        
        #if DEBUG
        if status != errSecSuccess {
            print("KeychainHelper: Failed to save key \(account): \(status)")
        }
        #endif
    }
    
    func read(service: String, account: String) -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ] as CFDictionary
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        
        #if DEBUG
        if status != errSecSuccess {
            print("KeychainHelper: Failed to read key \(account): \(status)")
        }
        #endif
        
        return nil
    }
    
    func delete(service: String, account: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ] as CFDictionary
        
        let status = SecItemDelete(query)
        
        #if DEBUG
        if status != errSecSuccess && status != errSecItemNotFound {
            print("KeychainHelper: Failed to delete key \(account): \(status)")
        }
        #endif
    }
    
    func exists(service: String, account: String) -> Bool {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ] as CFDictionary
        
        let status = SecItemCopyMatching(query, nil)
        return status == errSecSuccess
    }
}