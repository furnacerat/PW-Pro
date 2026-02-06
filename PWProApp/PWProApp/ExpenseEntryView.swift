import SwiftUI

struct ExpenseEntryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var financialManager = FinancialManager.shared
    
    @State private var category: ExpenseCategory = .other
    @State private var amount: String = ""
    @State private var vendor: String = ""
    @State private var note: String = ""
    @State private var date = Date()
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.slate900.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Amount Card
                        GlassCard {
                            VStack(spacing: 8) {
                                Text("TRANSACTION AMOUNT")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.slate500)
                                
                                HStack {
                                    Text("$")
                                        .font(.title.bold())
                                        .foregroundColor(Theme.sky500)
                                    TextField("0.00", text: $amount)
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.white)
                                        #if os(iOS)
                                        .keyboardType(.decimalPad)
                                        #endif
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.vertical, 30)
                        }
                        
                        // Category Selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("CATEGORY")
                                .font(Theme.labelFont)
                                .foregroundColor(Theme.slate500)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                                        CategoryCard(category: cat, isSelected: category == cat) {
                                            category = cat
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("TRANSACTION DETAILS")
                                .font(Theme.labelFont)
                                .foregroundColor(Theme.slate500)
                            
                            GlassCard {
                                VStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Vendor")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.slate500)
                                        TextField("e.g. Home Depot, Shell", text: $vendor)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Divider().background(Theme.slate700)
                                    
                                    DatePicker("Date", selection: $date, displayedComponents: .date)
                                        .accentColor(Theme.sky500)
                                    
                                    Divider().background(Theme.slate700)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Note")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.slate500)
                                        TextField("Optional note...", text: $note)
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                            }
                        }
                        
                        Spacer(minLength: 40)
                        
                        NeonButton(title: "Save Expense", color: Theme.emerald500, icon: "checkmark.circle.fill") {
                            saveExpense()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("New Expense")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.slate400)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Expense Saved", isPresented: $showingSuccess) {
            Button("Done") { dismiss() }
        }
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount) else { return }
        
        let expense = Expense(
            category: category,
            amount: amountValue,
            date: date,
            note: note,
            vendor: vendor
        )
        
        financialManager.addExpense(expense)
        showingSuccess = true
    }
}

struct CategoryCard: View {
    let category: ExpenseCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                Text(category.rawValue)
                    .font(.system(size: 10, weight: .bold))
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? Theme.sky500.opacity(0.2) : Theme.slate800.opacity(0.3))
            .foregroundColor(isSelected ? Theme.sky500 : Theme.slate400)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Theme.sky500 : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
