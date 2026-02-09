import XCTest
@testable import PWPro

// MARK: - Authentication Tests

class AuthenticationManagerTests: XCTestCase {
    var authManager: AuthenticationManager!
    
    override func setUp() {
        super.setUp()
        authManager = AuthenticationManager()
    }
    
    override func tearDown() {
        authManager = nil
        super.tearDown()
    }
    
    func testValidateEmail() {
        // Valid emails
        XCTAssertTrue(authManager.validateEmail("test@example.com"))
        XCTAssertTrue(authManager.validateEmail("user.name@domain.co.uk"))
        
        // Invalid emails
        XCTAssertFalse(authManager.validateEmail("invalid-email"))
        XCTAssertFalse(authManager.validateEmail("@domain.com"))
        XCTAssertFalse(authManager.validateEmail("user@"))
        XCTAssertFalse(authManager.validateEmail(""))
    }
    
    func testValidatePassword() {
        // Valid passwords
        XCTAssertTrue(authManager.validatePassword("password123"))
        XCTAssertTrue(authManager.validatePassword("123456"))
        
        // Invalid passwords
        XCTAssertFalse(authManager.validatePassword("123")) // Too short
        XCTAssertFalse(authManager.validatePassword(""))    // Empty
    }
    
    func testUserRoles() {
        // Test role properties
        let ownerAuth = authManager
        ownerAuth.updateUserRole(.owner)
        XCTAssertTrue(ownerAuth.canAccessBusinessFeatures)
        XCTAssertTrue(ownerAuth.canManageTeam)
        XCTAssertFalse(ownerAuth.isTechnician)
        
        let techAuth = authManager
        techAuth.updateUserRole(.technician)
        XCTAssertFalse(techAuth.canAccessBusinessFeatures)
        XCTAssertFalse(techAuth.canManageTeam)
        XCTAssertTrue(techAuth.isTechnician)
        
        let adminAuth = authManager
        adminAuth.updateUserRole(.admin)
        XCTAssertTrue(adminAuth.canAccessBusinessFeatures)
        XCTAssertTrue(adminAuth.canManageTeam)
        XCTAssertFalse(adminAuth.isTechnician)
    }
}

// MARK: - Validation Tests

class ValidationTests: XCTestCase {
    
    func testClientValidation() {
        let validClient = Client(
            id: UUID(),
            userId: UUID(),
            name: "John Doe",
            email: "john@example.com",
            phone: "+1 (555) 123-4567",
            address: nil,
            notes: nil,
            tags: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let result = validClient.validate()
        XCTAssertTrue(result.isValid, "Valid client should pass validation")
        
        // Test invalid client
        var invalidClient = validClient
        invalidClient.name = ""
        
        let invalidResult = invalidClient.validate()
        XCTAssertFalse(invalidResult.isValid, "Client without name should fail validation")
        XCTAssertTrue(invalidResult.errors.contains { $0.localizedDescription.contains("required") })
    }
    
    func testJobValidation() {
        let validJob = Job(
            id: UUID(),
            userId: UUID(),
            clientId: UUID(),
            title: "Pressure Washing",
            description: "House washing",
            status: "scheduled",
            price: 250.0,
            durationHours: 2,
            scheduledAt: Date().addingTimeInterval(86400), // Tomorrow
            completedAt: nil,
            weatherData: nil,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let result = validJob.validate()
        XCTAssertTrue(result.isValid, "Valid job should pass validation")
        
        // Test invalid job
        var invalidJob = validJob
        invalidJob.clientId = nil
        
        let invalidResult = invalidJob.validate()
        XCTAssertFalse(invalidResult.isValid, "Job without client should fail validation")
    }
    
    func testEmailValidator() {
        let validator = EmailValidator()
        
        // Valid emails
        XCTAssertTrue(validator.validate("test@example.com").isValid)
        XCTAssertTrue(validator.validate("user.name@domain.co.uk").isValid)
        
        // Invalid emails
        XCTAssertFalse(validator.validate("invalid-email").isValid)
        XCTAssertFalse(validator.validate("@domain.com").isValid)
        XCTAssertFalse(validator.validate("").isValid)
    }
    
    func testPhoneValidator() {
        let validator = PhoneValidator()
        
        // Valid phones
        XCTAssertTrue(validator.validate("+1 (555) 123-4567").isValid)
        XCTAssertTrue(validator.validate("555-123-4567").isValid)
        XCTAssertTrue(validator.validate("(555) 123-4567").isValid)
        
        // Invalid phones
        XCTAssertFalse(validator.validate("123").isValid)
        XCTAssertFalse(validator.validate("").isValid)
    }
    
    func testNumericValidator() {
        let validator = NumericValidator()
        
        // Valid numbers
        XCTAssertTrue(validator.validate("123.45").isValid)
        XCTAssertTrue(validator.validate("-50").isValid)
        XCTAssertTrue(validator.validate("0").isValid)
        
        // Invalid numbers
        XCTAssertFalse(validator.validate("abc").isValid)
        XCTAssertFalse(validator.validate("").isValid)
        
        // Test range validation
        let rangeValidator = NumericValidator(range: 0...100)
        XCTAssertTrue(rangeValidator.validate("50").isValid)
        XCTAssertFalse(rangeValidator.validate("150").isValid)
        XCTAssertFalse(rangeValidator.validate("-10").isValid)
    }
}

// MARK: - Data Model Tests

class DataModelTests: XCTestCase {
    
    func testClientCoding() {
        let client = Client(
            id: UUID(),
            userId: UUID(),
            name: "Test Client",
            email: "test@example.com",
            phone: "555-1234",
            address: ["street": "123 Main St", "city": "Anytown"],
            notes: "Test notes",
            tags: ["tag1", "tag2"],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try? encoder.encode(client)
        XCTAssertNotNil(data, "Client should be encodable")
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedClient = try? decoder.decode(Client.self, from: data!)
        XCTAssertNotNil(decodedClient, "Client should be decodable")
        
        // Test equality
        XCTAssertEqual(client.id, decodedClient?.id)
        XCTAssertEqual(client.name, decodedClient?.name)
        XCTAssertEqual(client.email, decodedClient?.email)
    }
    
    func testJobCoding() {
        let job = Job(
            id: UUID(),
            userId: UUID(),
            clientId: UUID(),
            title: "Test Job",
            description: "Test description",
            status: "scheduled",
            price: 250.0,
            durationHours: 2,
            scheduledAt: Date(),
            completedAt: nil,
            weatherData: ["temperature": "75°F", "conditions": "Sunny"],
            notes: "Test notes",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try? encoder.encode(job)
        XCTAssertNotNil(data, "Job should be encodable")
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedJob = try? decoder.decode(Job.self, from: data!)
        XCTAssertNotNil(decodedJob, "Job should be decodable")
        
        // Test equality
        XCTAssertEqual(job.id, decodedJob?.id)
        XCTAssertEqual(job.title, decodedJob?.title)
        XCTAssertEqual(job.price, decodedJob?.price)
    }
    
    func testEstimateCoding() {
        let estimate = Estimate(
            id: UUID(),
            userId: UUID(),
            clientId: UUID(),
            title: "Test Estimate",
            description: "Test description",
            totalAmount: 500.0,
            status: "draft",
            validUntil: Date().addingTimeInterval(86400 * 7), // 1 week
            lineItems: [["name": "Service 1", "amount": 250.0], ["name": "Service 2", "amount": 250.0]],
            propertyData: ["squareFeet": 2000, "stories": 2],
            aiAnalysis: ["surfaceType": "Vinyl", "difficulty": "Medium"],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try? encoder.encode(estimate)
        XCTAssertNotNil(data, "Estimate should be encodable")
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedEstimate = try? decoder.decode(Estimate.self, from: data!)
        XCTAssertNotNil(decodedEstimate, "Estimate should be decodable")
        
        // Test equality
        XCTAssertEqual(estimate.id, decodedEstimate?.id)
        XCTAssertEqual(estimate.title, decodedEstimate?.title)
        XCTAssertEqual(estimate.totalAmount, decodedEstimate?.totalAmount)
    }
}

// MARK: - Service Container Tests

class ServiceContainerTests: XCTestCase {
    var serviceContainer: ServiceContainer!
    
    override func setUp() {
        super.setUp()
        serviceContainer = ServiceContainer.shared
    }
    
    func testServiceRegistration() {
        // Register a test service
        serviceContainer.register(String.self) { "test" }
        
        // Resolve the service
        let resolvedService = serviceContainer.resolve(String.self)
        
        XCTAssertEqual(resolvedService, "test", "Should resolve registered service")
    }
    
    func testServiceInstanceRegistration() {
        // Register a test instance
        let testInstance = "test instance"
        serviceContainer.register(String.self, instance: testInstance)
        
        // Resolve the service
        let resolvedService = serviceContainer.resolve(String.self)
        
        XCTAssertTrue(resolvedService === testInstance, "Should resolve same instance")
    }
    
    func testUnregisteredService() {
        // Try to resolve an unregistered service
        XCTAssertThrowsError(try serviceContainer.resolve(Int.self), "Should throw error for unregistered service")
    }
}

// MARK: - Utility Tests

class UtilityTests: XCTestCase {
    
    func testValidationUtils() {
        // Test string sanitization
        XCTAssertEqual(ValidationUtils.sanitizeString("  test  "), "test")
        XCTAssertEqual(ValidationUtils.sanitizeString(nil), "")
        XCTAssertEqual(ValidationUtils.sanitizeString(""), "")
        
        // Test email sanitization
        XCTAssertEqual(ValidationUtils.sanitizeEmail("  TEST@EXAMPLE.COM  "), "test@example.com")
        XCTAssertEqual(ValidationUtils.sanitizeEmail(""), nil)
        XCTAssertEqual(ValidationUtils.sanitizeEmail(nil), nil)
        
        // Test phone sanitization
        XCTAssertEqual(ValidationUtils.sanitizePhone("(555) 123-4567"), "5551234567")
        XCTAssertEqual(ValidationUtils.sanitizePhone("+1 (555) 123-4567"), "15551234567")
        XCTAssertEqual(ValidationUtils.sanitizePhone(""), nil)
        XCTAssertEqual(ValidationUtils.sanitizePhone(nil), nil)
    }
    
    func testCurrencyFormatting() {
        XCTAssertEqual(ValidationUtils.formatCurrency(123.45), "$123.45")
        XCTAssertEqual(ValidationUtils.formatCurrency(0), "$0.00")
        XCTAssertEqual(ValidationUtils.formatCurrency(1000), "$1,000.00")
    }
    
    func testPhoneFormatting() {
        XCTAssertEqual(ValidationUtils.formatPhoneNumber("5551234567"), "(555) 123-4567")
        XCTAssertEqual(ValidationUtils.formatPhoneNumber("15551234567"), "1 (555) 123-4567")
        XCTAssertEqual(ValidationUtils.formatPhoneNumber("123"), "123") // Too short, returns original
    }
}

// MARK: - Error Handling Tests

class ErrorHandlingTests: XCTestCase {
    var errorManager: ErrorManager!
    
    override func setUp() {
        super.setUp()
        errorManager = ErrorManager.shared
        errorManager.clearErrors()
    }
    
    func testErrorMapping() {
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        errorManager.handle(networkError, context: "Test")
        
        XCTAssertEqual(errorManager.errors.count, 1)
        XCTAssertTrue(errorManager.currentError is AppError)
        
        if let appError = errorManager.currentError as? AppError {
            switch appError {
            case .networkError:
                XCTAssertTrue(true, "Should map network error correctly")
            default:
                XCTFail("Should map to network error")
            }
        }
    }
    
    func testValidationErrors() {
        errorManager.handleValidation("Email is required")
        
        XCTAssertEqual(errorManager.errors.count, 1)
        XCTAssertTrue(errorManager.currentError is AppError)
        
        if let appError = errorManager.currentError as? AppError {
            switch appError {
            case .validationError(let message):
                XCTAssertEqual(message, "Email is required")
            default:
                XCTFail("Should map to validation error")
            }
        }
    }
    
    func testErrorClearing() {
        errorManager.handle(NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"]))
        XCTAssertEqual(errorManager.errors.count, 1)
        
        errorManager.clearErrors()
        XCTAssertEqual(errorManager.errors.count, 0)
        XCTAssertNil(errorManager.currentError)
        XCTAssertFalse(errorManager.hasErrors)
    }
}

// MARK: - Network Monitor Tests

class NetworkMonitorTests: XCTestCase {
    var networkMonitor: NetworkMonitor!
    
    override func setUp() {
        super.setUp()
        networkMonitor = NetworkMonitor.shared
    }
    
    func testNetworkMonitorInitialization() {
        XCTAssertNotNil(networkMonitor)
        XCTAssertTrue(networkMonitor.isConnected != nil) // Should be initialized
    }
    
    // Note: Network monitoring tests are limited in unit tests due to the nature of network monitoring
    // These would be better suited for integration tests
}

// MARK: - Theme Tests

class ThemeTests: XCTestCase {
    
    func testThemeColors() {
        // Test that theme colors are accessible
        XCTAssertNotNil(Theme.sky500)
        XCTAssertNotNil(Theme.slate900)
        XCTAssertNotNil(Theme.emerald500)
    }
    
    func testTypography() {
        // Test that typography is accessible
        XCTAssertNotNil(Theme.font(.largeTitle))
        XCTAssertNotNil(Theme.font(.caption))
    }
}

// MARK: - Performance Tests

class PerformanceTests: XCTestCase {
    
    func testValidationPerformance() {
        let validator = EmailValidator()
        let email = "test@example.com"
        
        measure {
            for _ in 0..<1000 {
                _ = validator.validate(email)
            }
        }
    }
    
    func testDataModelEncodingPerformance() {
        let client = Client(
            id: UUID(),
            userId: UUID(),
            name: "Performance Test Client",
            email: "test@example.com",
            phone: nil,
            address: nil,
            notes: nil,
            tags: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let encoder = JSONEncoder()
        
        measure {
            for _ in 0..<100 {
                _ = try? encoder.encode(client)
            }
        }
    }
    
    func testDataModelDecodingPerformance() {
        let client = Client(
            id: UUID(),
            userId: UUID(),
            name: "Performance Test Client",
            email: "test@example.com",
            phone: nil,
            address: nil,
            notes: nil,
            tags: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try! encoder.encode(client)
        
        measure {
            for _ in 0..<100 {
                _ = try? decoder.decode(Client.self, from: data)
            }
        }
    }
}

// MARK: - Integration Tests

class IntegrationTests: XCTestCase {
    
    func testEndToEndClientWorkflow() {
        // Create client
        let client = Client(
            id: UUID(),
            userId: UUID(),
            name: "Integration Test Client",
            email: "integration@example.com",
            phone: "(555) 123-4567",
            address: nil,
            notes: nil,
            tags: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Validate client
        let validationResult = client.validate()
        XCTAssertTrue(validationResult.isValid, "Client should be valid")
        
        // Encode client
        let encoder = JSONEncoder()
        let data = try? encoder.encode(client)
        XCTAssertNotNil(data, "Client should be encodable")
        
        // Decode client
        let decoder = JSONDecoder()
        let decodedClient = try? decoder.decode(Client.self, from: data!)
        XCTAssertNotNil(decodedClient, "Client should be decodable")
        
        // Validate decoded client
        let decodedValidationResult = decodedClient!.validate()
        XCTAssertTrue(decodedValidationResult.isValid, "Decoded client should still be valid")
    }
    
    func testEndToEndJobWorkflow() {
        // Create job with client
        let clientId = UUID()
        let job = Job(
            id: UUID(),
            userId: UUID(),
            clientId: clientId,
            title: "Integration Test Job",
            description: "Test job description",
            status: "scheduled",
            price: 250.0,
            durationHours: 2,
            scheduledAt: Date().addingTimeInterval(86400),
            completedAt: nil,
            weatherData: nil,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Validate job
        let validationResult = job.validate()
        XCTAssertTrue(validationResult.isValid, "Job should be valid")
        
        // Test workflow simulation
        XCTAssertEqual(job.status, "scheduled")
        
        // Simulate job completion
        var completedJob = job
        completedJob.status = "completed"
        completedJob.completedAt = Date()
        
        let completedValidationResult = completedJob.validate()
        XCTAssertTrue(completedValidationResult.isValid, "Completed job should be valid")
    }
}