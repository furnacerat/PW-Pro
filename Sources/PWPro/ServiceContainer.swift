import Foundation

// MARK: - Service Container

@MainActor
class ServiceContainer {
    static let shared = ServiceContainer()
    
    private var services: [String: Any] = [:]
    
    private init() {}
    
    // MARK: - Registration
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        services[key] = factory
    }
    
    func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        services[key] = instance
    }
    
    // MARK: - Resolution
    
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        if let factory = services[key] as? () -> T {
            return factory()
        } else if let instance = services[key] as? T {
            return instance
        } else {
            fatalError("Service of type \(type) not registered")
        }
    }
    
    // MARK: - Convenience Methods
    
    func registerSupabaseServices() {
        // Register SupabaseManager
        register(SupabaseManager.self) {
            SupabaseManager.shared
        }
        
        // Register managers with Supabase integration
        register(ClientManager.self) {
            ClientManager()
        }
        
        register(SchedulingManager.self) {
            SchedulingManager()
        }
        
        register(EstimateManager.self) {
            EstimateManager()
        }
        
        register(InvoiceManager.self) {
            InvoiceManager()
        }
        
        register(EquipmentManager.self) {
            EquipmentManager()
        }
        
        register(ChemicalInventoryManager.self) {
            ChemicalInventoryManager()
        }
        
        register(ExpenseManager.self) {
            ExpenseManager()
        }
        
        register(BusinessSettingsManager.self) {
            BusinessSettingsManager()
        }
        
        register(LeadManager.self) {
            LeadManager()
        }
        
        // Register utilities
        register(AuthenticationManager.self) {
            AuthenticationManager()
        }
        
        register(NetworkMonitor.self) {
            NetworkMonitor.shared
        }
        
        register(HapticManager.self) {
            HapticManager()
        }
        
        register(OfflineSyncManager.self) {
            OfflineSyncManager()
        }
    }
}

// MARK: - Property Wrapper

@propertyWrapper
struct Injected<T> {
    private let keyPath: KeyPath<ServiceContainer, T>
    private let container: ServiceContainer
    
    var wrappedValue: T {
        return container[keyPath: keyPath]
    }
    
    init(_ keyPath: KeyPath<ServiceContainer, T>, container: ServiceContainer = .shared) {
        self.keyPath = keyPath
        self.container = container
    }
}

// MARK: - Service Locator Extensions

extension ServiceContainer {
    var supabaseManager: SupabaseManager {
        return resolve(SupabaseManager.self)
    }
    
    var authenticationManager: AuthenticationManager {
        return resolve(AuthenticationManager.self)
    }
    
    var clientManager: ClientManager {
        return resolve(ClientManager.self)
    }
    
    var schedulingManager: SchedulingManager {
        return resolve(SchedulingManager.self)
    }
    
    var estimateManager: EstimateManager {
        return resolve(EstimateManager.self)
    }
    
    var invoiceManager: InvoiceManager {
        return resolve(InvoiceManager.self)
    }
    
    var equipmentManager: EquipmentManager {
        return resolve(EquipmentManager.self)
    }
    
    var chemicalInventoryManager: ChemicalInventoryManager {
        return resolve(ChemicalInventoryManager.self)
    }
    
    var expenseManager: ExpenseManager {
        return resolve(ExpenseManager.self)
    }
    
    var businessSettingsManager: BusinessSettingsManager {
        return resolve(BusinessSettingsManager.self)
    }
    
    var leadManager: LeadManager {
        return resolve(LeadManager.self)
    }
    
    var networkMonitor: NetworkMonitor {
        return resolve(NetworkMonitor.self)
    }
    
    var hapticManager: HapticManager {
        return resolve(HapticManager.self)
    }
    
    var offlineSyncManager: OfflineSyncManager {
        return resolve(OfflineSyncManager.self)
    }
}

// MARK: - Service Protocol

protocol Service {
    init()
}

// MARK: - Base Manager Protocol

protocol BaseManager: ObservableObject {
    var isLoading: Bool { get set }
    var error: String? { get set }
    func handleError(_ error: Error, context: String)
}

// MARK: - Default Implementation

extension BaseManager {
    func handleError(_ error: Error, context: String) {
        let message = error.localizedDescription
        
        if message.contains("network") || message.contains("offline") {
            self.error = "Network error. Please check your internet connection."
        } else if message.contains("unauthorized") {
            self.error = "You are not authorized to perform this action."
        } else if message.contains("not_found") {
            self.error = "The requested resource was not found."
        } else {
            self.error = "\(context) failed: \(message)"
        }
        
        print("\(context) failed: \(message)")
    }
}

// MARK: - Service Factory

class ServiceFactory {
    @MainActor
    static func initializeServices() {
        let container = ServiceContainer.shared
        container.registerSupabaseServices()
        
        // Initialize managers to ensure they're ready
        _ = container.authenticationManager
        _ = container.supabaseManager
        _ = container.networkMonitor
        
        print("Services initialized successfully")
    }
}