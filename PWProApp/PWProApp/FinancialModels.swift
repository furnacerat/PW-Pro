import Foundation
import SwiftUI

enum ExpenseCategory: String, Codable, CaseIterable {
    case chemicals = "Chemicals"
    case gas = "Gas / Fuel"
    case equipment = "Equipment"
    case advertising = "Advertising"
    case insurance = "Insurance"
    case repairs = "Repairs"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .chemicals: return "flask.fill"
        case .gas: return "fuelpump.fill"
        case .equipment: return "hammer.fill"
        case .advertising: return "megaphone.fill"
        case .insurance: return "shield.lefthalf.filled"
        case .repairs: return "wrench.adjustable.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

struct Expense: Identifiable, Codable {
    var id = UUID()
    let category: ExpenseCategory
    let amount: Double
    let date: Date
    let note: String
    let vendor: String
}

@MainActor
class FinancialManager: ObservableObject {
    @Published var expenses: [Expense] = [] {
        didSet { save() }
    }
    
    private let filename = "expenses.json"
    static let shared = FinancialManager()
    
    private init() {
        load()
        if expenses.isEmpty {
            // Mock data if nothing loaded
            expenses = [
                Expense(category: .chemicals, amount: 85.50, date: Date().addingTimeInterval(-86400 * 2), note: "SH and Surfactant", vendor: "Local Supply"),
                Expense(category: .gas, amount: 45.00, date: Date().addingTimeInterval(-86400), note: "Truck Fill up", vendor: "Shell"),
                Expense(category: .equipment, amount: 120.00, date: Date(), note: "New Spray Gun", vendor: "Pressure Wash Store")
            ]
            save()
        }
    }
    
    func save() {
        StorageManager.shared.save(expenses, to: filename)
    }
    
    private func load() {
        if let loaded: [Expense] = StorageManager.shared.load([Expense].self, from: filename) {
            self.expenses = loaded
        }
    }
    
    func addExpense(_ expense: Expense) {
        expenses.append(expense)
    }
    
    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    func totalExpenses(for date: Date, isLifetime: Bool = false) -> Double {
        if isLifetime { return totalExpenses }
        let components = Calendar.current.dateComponents([.month, .year], from: date)
        return totalExpenses(for: components.month ?? 0, year: components.year ?? 0)
    }
    
    func totalExpenses(for month: Int, year: Int) -> Double {
        expenses.filter { 
            let components = Calendar.current.dateComponents([.month, .year], from: $0.date)
            return components.month == month && components.year == year
        }.reduce(0) { $0 + $1.amount }
    }
    
    func totalRevenue(for date: Date, invoices: [Invoice], isLifetime: Bool = false) -> Double {
        if isLifetime {
            return invoices.filter { $0.status == .paid }.reduce(0) { $0 + $1.total }
        }
        let components = Calendar.current.dateComponents([.month, .year], from: date)
        return totalRevenue(for: components.month ?? 0, year: components.year ?? 0, invoices: invoices)
    }
    
    func totalRevenue(for month: Int, year: Int, invoices: [Invoice]) -> Double {
        invoices.filter {
            let components = Calendar.current.dateComponents([.month, .year], from: $0.date)
            return components.month == month && components.year == year && $0.status == .paid
        }.reduce(0) { $0 + $1.total }
    }
}
