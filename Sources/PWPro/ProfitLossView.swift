import SwiftUI

struct ProfitLossView: View {
    @StateObject var financialManager = FinancialManager.shared
    @StateObject var invoiceManager = InvoiceManager.shared
    @State private var showingExpenseEntry = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Main Stats Card
                GlassCard {
                    VStack(spacing: 20) {
                        Text("NET PROFIT (LIFETIME)")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                        
                        let totalRev = financialManager.totalRevenue(for: Date(), invoices: invoiceManager.invoices, isLifetime: true)
                        let totalExp = financialManager.totalExpenses
                        let profit = totalRev - totalExp
                        
                        Text(String(format: "$%.2f", profit))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(profit >= 0 ? Theme.emerald500 : Theme.red500)
                        
                        HStack(spacing: 40) {
                            StatMiniView(label: "REVENUE", value: totalRev, color: Theme.emerald500)
                            StatMiniView(label: "EXPENSES", value: totalExp, color: Theme.red500)
                        }
                    }
                    .padding(.vertical, 30)
                }
                
                // Monthly Performance
                VStack(alignment: .leading, spacing: 16) {
                    Text("MONTHLY PERFORMANCE")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate500)
                    
                    GlassCard {
                        VStack(spacing: 16) {
                            ForEach(0..<3) { i in
                                let date = Calendar.current.date(byAdding: .month, value: -i, to: Date())!
                                let month = Calendar.current.component(.month, from: date)
                                let year = Calendar.current.component(.year, from: date)
                                
                                let mRev = financialManager.totalRevenue(for: month, year: year, invoices: invoiceManager.invoices)
                                let mExp = financialManager.totalExpenses(for: month, year: year)
                                
                                MonthlyRow(date: date, revenue: mRev, expenses: mExp)
                                
                                if i < 2 { Divider().background(Theme.slate700) }
                            }
                        }
                        .padding()
                    }
                }
                
                // Expense Breakdown
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("RECENT EXPENSES")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                        Spacer()
                        Button {
                            showingExpenseEntry = true
                        } label: {
                            Text("+ Add New")
                                .font(.caption.bold())
                                .foregroundColor(Theme.sky500)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        if financialManager.expenses.isEmpty {
                            Text("No expenses recorded yet")
                                .font(.caption)
                                .foregroundColor(Theme.slate600)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(financialManager.expenses.reversed().prefix(5)) { expense in
                                ExpenseRow(expense: expense)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Theme.slate900)
        .navigationTitle("Profit & Loss")
        .sheet(isPresented: $showingExpenseEntry) {
            ExpenseEntryView()
        }
    }
}



struct StatMiniView: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Theme.slate500)
            Text(String(format: "$%.0f", value))
                .font(.headline.bold())
                .foregroundColor(color)
        }
    }
}

struct MonthlyRow: View {
    let date: Date
    let revenue: Double
    let expenses: Double
    
    var body: some View {
        HStack {
            Text(date, format: .dateTime.month(.wide))
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "+$%.0f", revenue))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.emerald500)
                Text(String(format: "-$%.0f", expenses))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.red500)
            }
            
            let profit = revenue - expenses
            Text(String(format: "$%.0f", profit))
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 60, alignment: .trailing)
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                Image(systemName: expense.category.icon)
                    .foregroundColor(Theme.sky500)
                    .frame(width: 32, height: 32)
                    .background(Theme.sky500.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.vendor.isEmpty ? expense.category.rawValue : expense.vendor)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                    Text(expense.date, format: .dateTime.month().day())
                        .font(.system(size: 8))
                        .foregroundColor(Theme.slate500)
                }
                
                Spacer()
                
                Text(String(format: "-$%.2f", expense.amount))
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
        }
    }
}
