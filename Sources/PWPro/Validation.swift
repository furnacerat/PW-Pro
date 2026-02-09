import Foundation

// MARK: - Validation Protocols

protocol Validatable {
    func validate() -> ValidationResult
}

protocol FieldValidator {
    func validate(_ value: String?) -> ValidationResult
}

// MARK: - Validation Result

struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
    
    static let valid = ValidationResult(isValid: true, errors: [])
    
    init(isValid: Bool, errors: [ValidationError] = []) {
        self.isValid = isValid && errors.isEmpty
        self.errors = errors
    }
    
    init(error: ValidationError) {
        self.isValid = false
        self.errors = [error]
    }
}

enum ValidationError: LocalizedError {
    case required
    case invalidEmail
    case invalidPhone
    case tooShort(minLength: Int)
    case tooLong(maxLength: Int)
    case invalidFormat(expected: String)
    case invalidNumber(range: ClosedRange<Double>?)
    case invalidDate
    case futureDate
    case pastDate
    case custom(message: String)
    
    var errorDescription: String? {
        switch self {
        case .required:
            return "This field is required."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .invalidPhone:
            return "Please enter a valid phone number."
        case .tooShort(let minLength):
            return "Must be at least \(minLength) characters long."
        case .tooLong(let maxLength):
            return "Must be no more than \(maxLength) characters long."
        case .invalidFormat(let expected):
            return "Invalid format. Expected: \(expected)."
        case .invalidNumber(let range):
            if let range = range {
                return "Must be between \(range.lowerBound) and \(range.upperBound)."
            } else {
                return "Must be a valid number."
            }
        case .invalidDate:
            return "Please enter a valid date."
        case .futureDate:
            return "Date cannot be in the future."
        case .pastDate:
            return "Date cannot be in the past."
        case .custom(let message):
            return message
        }
    }
}

// MARK: - Field Validators

struct EmailValidator: FieldValidator {
    func validate(_ value: String?) -> ValidationResult {
        guard let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ValidationResult(error: .required)
        }
        
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if emailPredicate.evaluate(with: value) {
            return .valid
        } else {
            return ValidationResult(error: .invalidEmail)
        }
    }
}

struct PhoneValidator: FieldValidator {
    func validate(_ value: String?) -> ValidationResult {
        guard let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ValidationResult(error: .required)
        }
        
        let phoneRegex = #"^(\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$"#
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        
        if phonePredicate.evaluate(with: value) {
            return .valid
        } else {
            return ValidationResult(error: .invalidPhone)
        }
    }
}

struct RequiredValidator: FieldValidator {
    func validate(_ value: String?) -> ValidationResult {
        if let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .valid
        } else {
            return ValidationResult(error: .required)
        }
    }
}

struct LengthValidator: FieldValidator {
    let minLength: Int
    let maxLength: Int?
    
    init(minLength: Int = 0, maxLength: Int? = nil) {
        self.minLength = minLength
        self.maxLength = maxLength
    }
    
    func validate(_ value: String?) -> ValidationResult {
        guard let value = value else {
            return ValidationResult(error: .required)
        }
        
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        var errors: [ValidationError] = []
        
        if trimmed.count < minLength {
            errors.append(.tooShort(minLength: minLength))
        }
        
        if let maxLength = maxLength, trimmed.count > maxLength {
            errors.append(.tooLong(maxLength: maxLength))
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

struct NumericValidator: FieldValidator {
    let range: ClosedRange<Double>?
    
    init(range: ClosedRange<Double>? = nil) {
        self.range = range
    }
    
    func validate(_ value: String?) -> ValidationResult {
        guard let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ValidationResult(error: .required)
        }
        
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let number = Double(trimmed) else {
            return ValidationResult(error: .invalidNumber(range: nil))
        }
        
        if let range = range, !range.contains(number) {
            return ValidationResult(error: .invalidNumber(range: range))
        }
        
        return .valid
    }
}

struct DateValidator: FieldValidator {
    let allowFuture: Bool
    let allowPast: Bool
    
    init(allowFuture: Bool = true, allowPast: Bool = true) {
        self.allowFuture = allowFuture
        self.allowPast = allowPast
    }
    
    func validate(_ value: Date?) -> ValidationResult {
        guard let date = value else {
            return ValidationResult(error: .required)
        }
        
        var errors: [ValidationError] = []
        
        if !allowFuture && date > Date() {
            errors.append(.futureDate)
        }
        
        if !allowPast && date < Date() {
            errors.append(.pastDate)
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

// MARK: - Business Model Validators

struct ClientValidator {
    static func validate(_ client: Client) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Name validation
        let nameResult = RequiredValidator().validate(client.name)
        if !nameResult.isValid {
            errors.append(contentsOf: nameResult.errors)
        }
        
        // Email validation (optional but if provided, must be valid)
        if let email = client.email, !email.isEmpty {
            let emailResult = EmailValidator().validate(email)
            if !emailResult.isValid {
                errors.append(contentsOf: emailResult.errors)
            }
        }
        
        // Phone validation (optional but if provided, must be valid)
        if let phone = client.phone, !phone.isEmpty {
            let phoneResult = PhoneValidator().validate(phone)
            if !phoneResult.isValid {
                errors.append(contentsOf: phoneResult.errors)
            }
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

struct JobValidator {
    static func validate(_ job: Job) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Title validation
        let titleResult = RequiredValidator().validate(job.title)
        if !titleResult.isValid {
            errors.append(contentsOf: titleResult.errors)
        }
        
        // Client validation
        if job.clientId == nil {
            errors.append(.custom(message: "Please select a client for this job."))
        }
        
        // Price validation (optional but if provided, must be positive)
        if let price = job.price, price < 0 {
            errors.append(.custom(message: "Price cannot be negative."))
        }
        
        // Duration validation (optional but if provided, must be positive)
        if let duration = job.durationHours, duration <= 0 {
            errors.append(.custom(message: "Duration must be greater than 0."))
        }
        
        // Scheduled date validation
        if let scheduledAt = job.scheduledAt {
            let dateResult = DateValidator(allowFuture: true, allowPast: false).validate(scheduledAt)
            if !dateResult.isValid {
                errors.append(contentsOf: dateResult.errors)
            }
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

struct EstimateValidator {
    static func validate(_ estimate: Estimate) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Title validation
        let titleResult = RequiredValidator().validate(estimate.title)
        if !titleResult.isValid {
            errors.append(contentsOf: titleResult.errors)
        }
        
        // Client validation
        if estimate.clientId == nil {
            errors.append(.custom(message: "Please select a client for this estimate."))
        }
        
        // Amount validation (optional but if provided, must be positive)
        if let amount = estimate.totalAmount, amount < 0 {
            errors.append(.custom(message: "Total amount cannot be negative."))
        }
        
        // Valid until date validation
        if let validUntil = estimate.validUntil {
            let dateResult = DateValidator(allowFuture: true, allowPast: false).validate(validUntil)
            if !dateResult.isValid {
                errors.append(contentsOf: dateResult.errors)
            }
        }
        
        // Line items validation
        if let lineItems = estimate.lineItems, lineItems.isEmpty {
            errors.append(.custom(message: "Please add at least one line item to the estimate."))
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

struct InvoiceValidator {
    static func validate(_ invoice: Invoice) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Invoice number validation
        let invoiceNumberResult = RequiredValidator().validate(invoice.invoiceNumber)
        if !invoiceNumberResult.isValid {
            errors.append(contentsOf: invoiceNumberResult.errors)
        }
        
        // Client validation
        if invoice.clientId == nil {
            errors.append(.custom(message: "Please select a client for this invoice."))
        }
        
        // Amount validation
        if let amount = invoice.totalAmount {
            if amount < 0 {
                errors.append(.custom(message: "Total amount cannot be negative."))
            }
        } else {
            errors.append(.custom(message: "Total amount is required."))
        }
        
        // Due date validation
        if let dueDate = invoice.dueDate {
            let dateResult = DateValidator(allowFuture: true, allowPast: true).validate(dueDate)
            if !dateResult.isValid {
                errors.append(contentsOf: dateResult.errors)
            }
        }
        
        // Line items validation
        if let lineItems = invoice.lineItems, lineItems.isEmpty {
            errors.append(.custom(message: "Please add at least one line item to the invoice."))
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

struct ExpenseValidator {
    static func validate(_ expense: Expense) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Description validation
        let descriptionResult = RequiredValidator().validate(expense.description)
        if !descriptionResult.isValid {
            errors.append(contentsOf: descriptionResult.errors)
        }
        
        // Amount validation
        if expense.amount <= 0 {
            errors.append(.custom(message: "Amount must be greater than 0."))
        }
        
        // Category validation
        let categoryResult = RequiredValidator().validate(expense.category)
        if !categoryResult.isValid {
            errors.append(contentsOf: categoryResult.errors)
        }
        
        // Date validation
        let dateResult = DateValidator(allowFuture: false, allowPast: true).validate(expense.date)
        if !dateResult.isValid {
            errors.append(contentsOf: dateResult.errors)
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

struct EquipmentValidator {
    static func validate(_ equipment: Equipment) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Name validation
        let nameResult = RequiredValidator().validate(equipment.name)
        if !nameResult.isValid {
            errors.append(contentsOf: nameResult.errors)
        }
        
        // Health score validation
        if let healthScore = equipment.healthScore {
            if healthScore < 0 || healthScore > 100 {
                errors.append(.custom(message: "Health score must be between 0 and 100."))
            }
        }
        
        // Purchase price validation (optional but if provided, must be positive)
        if let price = equipment.purchasePrice, price < 0 {
            errors.append(.custom(message: "Purchase price cannot be negative."))
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

// MARK: - Validation Extensions

extension Client: Validatable {
    func validate() -> ValidationResult {
        return ClientValidator.validate(self)
    }
}

extension Job: Validatable {
    func validate() -> ValidationResult {
        return JobValidator.validate(self)
    }
}

extension Estimate: Validatable {
    func validate() -> ValidationResult {
        return EstimateValidator.validate(self)
    }
}

extension Invoice: Validatable {
    func validate() -> ValidationResult {
        return InvoiceValidator.validate(self)
    }
}

extension Expense: Validatable {
    func validate() -> ValidationResult {
        return ExpenseValidator.validate(self)
    }
}

extension Equipment: Validatable {
    func validate() -> ValidationResult {
        return EquipmentValidator.validate(self)
    }
}

// MARK: - Validation Utilities

struct ValidationUtils {
    static func sanitizeString(_ input: String?) -> String {
        guard let input = input else { return "" }
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func sanitizeEmail(_ email: String?) -> String? {
        let sanitized = sanitizeString(email).lowercased()
        return sanitized.isEmpty ? nil : sanitized
    }
    
    static func sanitizePhone(_ phone: String?) -> String? {
        guard let phone = phone else { return nil }
        let digits = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        return digits.isEmpty ? nil : digits
    }
    
    static func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    static func formatPhoneNumber(_ phone: String) -> String {
        let digits = sanitizePhone(phone) ?? ""
        
        guard digits.count >= 10 else { return phone }
        
        let areaCode = String(digits.prefix(3))
        let middle = String(digits.dropFirst(3).prefix(3))
        let last = String(digits.dropFirst(6).prefix(4))
        
        if digits.count == 10 {
            return "(\(areaCode)) \(middle)-\(last)"
        } else if digits.count > 10, digits.hasPrefix("1") {
            return "1 (\(areaCode)) \(middle)-\(last)"
        } else {
            return phone
        }
    }
}

// MARK: - Validation View Modifier

struct ValidationBorder: ViewModifier {
    let isValid: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isValid ? Color.green : Color.red, lineWidth: 1)
            )
    }
}

extension View {
    func validationBorder(isValid: Bool) -> some View {
        modifier(ValidationBorder(isValid: isValid))
    }
}