import SwiftUI

struct ChemicalsView: View {
    @StateObject var inventoryManager = ChemicalInventoryManager.shared
    @State private var searchText = ""
    @State private var selectedType: ChemicalType?
    @State private var selectedTab = 0 // 0: Library, 1: Inventory
    
    var filteredChemicals: [Chemical] {
        ChemicalData.allChemicals.filter { chemical in
            let matchesSearch = searchText.isEmpty || 
                chemical.name.localizedCaseInsensitiveContains(searchText) ||
                chemical.description.localizedCaseInsensitiveContains(searchText)
            
            let matchesType = selectedType == nil || chemical.type == selectedType
            
            return matchesSearch && matchesType
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    Text("Library").tag(0)
                    Text("Inventory").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedTab == 0 {
                    // Library View
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            FilterChip(title: "All", isSelected: selectedType == nil) {
                                selectedType = nil
                            }
                            
                            ForEach(ChemicalType.allCases, id: \.self) { type in
                                FilterChip(title: type.rawValue, isSelected: selectedType == type, color: type.color) {
                                    selectedType = type
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Theme.slate800.opacity(0.5))
                    
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredChemicals) { chemical in
                                ChemicalRow(chemical: chemical)
                            }
                        }
                        .padding()
                    }
                } else {
                    // Inventory View
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("STOCK LEVELS")
                                .font(Theme.labelFont)
                                .foregroundColor(Theme.slate400)
                                .padding(.horizontal)
                            
                            ForEach(inventoryManager.stocks) { stock in
                                GlassCard {
                                    VStack(spacing: 12) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(stock.chemical.name)
                                                    .font(.caption.bold())
                                                    .foregroundColor(.white)
                                                Text("\(Int(stock.currentGallons)) / \(Int(stock.capacityGallons)) Gal")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(Theme.slate400)
                                            }
                                            Spacer()
                                            if stock.currentGallons < stock.lowStockThreshold {
                                                Text("LOW STOCK")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Theme.red500.opacity(0.2))
                                                    .foregroundColor(Theme.red500)
                                                    .cornerRadius(4)
                                            }
                                        }
                                        
                                        ProgressView(value: stock.fillPercentage)
                                            .tint(stock.fillPercentage < 0.2 ? Theme.red500 : Theme.sky500)
                                        
                                        HStack {
                                            NeonButton(title: "Add 5 Gal", color: Theme.emerald500) {
                                                inventoryManager.addStock(chemicalID: stock.chemical.id, gallons: 5)
                                            }
                                            .frame(height: 30)
                                            
                                            NeonButton(title: "Log Use", color: Theme.sky500) {
                                                inventoryManager.deductStock(chemicalID: stock.chemical.id, gallons: 2)
                                            }
                                            .frame(height: 30)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Theme.slate900)
            .navigationTitle(selectedTab == 0 ? "Chemical Library" : "Stock Inventory")
            .searchable(text: $searchText, isPresented: .constant(selectedTab == 0), prompt: "Search chemicals...")
        }
    }
}

struct ChemicalRow: View {
    let chemical: Chemical
    @State private var isExpanded = false
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(chemical.name)
                                .font(Theme.headingFont.weight(.bold))
                                .foregroundColor(.white)
                            
                            if chemical.isBrandName {
                                Text("BRAND")
                                    .font(Theme.labelFont)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.sky500)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(chemical.type.rawValue)
                            .font(Theme.labelFont)
                            .foregroundColor(chemical.type.color)
                    }
                    Spacer()
                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.slate400)
                    }
                    .buttonStyle(.plain)
                }
                
                if isExpanded {
                    Text(chemical.description)
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.slate50)
                        .padding(.vertical, 4)
                    
                    Divider().background(Theme.slate400)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("USES:")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.sky500)
                        ForEach(chemical.uses, id: \.self) { use in
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.emerald500)
                                    .font(.caption)
                                Text(use)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.slate400)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WARNINGS:")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.amber500)
                        ForEach(chemical.warnings, id: \.self) { warning in
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Theme.amber500)
                                    .font(.caption)
                                Text(warning)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.slate400)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = Theme.sky500
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.labelFont)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color.clear)
                .foregroundColor(isSelected ? .white : Theme.slate400)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? color : Theme.slate400, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
