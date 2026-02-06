import SwiftUI

// MARK: - Models

enum SurfaceType: String, CaseIterable, Identifiable, Codable {
    case siding = "House Siding"
    case roof = "Roof (Shingle)"
    case concrete = "Concrete/Driveway"
    case deck = "Wood Deck"
    case fence = "Vinyl Fence"
    case gutters = "Gutter Cleaning"
    case solarPanels = "Solar Panels"
    case poolDeck = "Pool Deck"
    case windows = "Window Cleaning"
    case pavers = "Paver Sealing"
    case rust = "Rust Removal"
    case custom = "Custom Item"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .siding: return "house.fill"
        case .roof: return "/Users/haroldfoster/.gemini/antigravity/brain/e0d007e0-3a6d-4f71-b72f-02909daf1c9f/simple_roof_icon_1769205045359.png"
        case .concrete: return "car.fill"
        case .deck: return "table.furniture.fill"
        case .fence: return "square.grid.2x2.fill"
        case .gutters: return "pipe.and.drop.fill"
        case .solarPanels: return "sun.max.fill"
        case .poolDeck: return "figure.pool.swim"
        case .windows: return "square.split.2x2.fill"
        case .pavers: return "fossil.shell.fill"
        case .rust: return "exclamationmark.triangle.fill"
        case .custom: return "plus.circle.fill"
        }
    }
    
    var isSystemIcon: Bool {
        !icon.contains("/")
    }
    
    var baseCoverageRate: Double {
        switch self {
        case .siding: return 250
        case .roof: return 100
        case .concrete: return 150
        case .deck: return 125
        case .fence: return 200
        case .gutters, .solarPanels, .windows, .rust: return 500 // Specialized/Manual
        case .poolDeck, .pavers: return 125
        case .custom: return 200
        }
    }
}

struct EstimateItem: Identifiable, Codable {
    var id = UUID()
    var surface: SurfaceType = .siding
    var customName: String = ""
    var squareFootage: Double = 500
    var condition: SurfaceCondition = .average
    
    var displayName: String {
        surface == .custom ? customName : surface.rawValue
    }
}

struct Estimate: Identifiable, Codable {
    var id = UUID()
    var items: [EstimateItem] = [EstimateItem()]
    var selectedChemicals: Set<UUID> = []
    
    // Global Pricing Override/Common
    var pricingModel: PricingModel = .perSquareFoot
    var pricePerSqFt: Double = 0.15
    var laborHours: Double = 4
    var hourlyRate: Double = 150
    var materialMarkup: Double = 1.3
}

enum SurfaceCondition: String, CaseIterable, Identifiable, Codable {
    case light = "Light Maintenance"
    case average = "Average Soiling"
    case heavy = "Heavy / Organic Growth"
    
    var id: String { rawValue }
    
    var multiplier: Double {
        switch self {
        case .light: return 1.2
        case .average: return 1.0
        case .heavy: return 0.7
        }
    }
}

enum PricingModel: String, CaseIterable, Codable {
    case perSquareFoot = "Per Sq. Ft."
    case costPlus = "Cost Plus"
}

// MARK: - View

struct EstimatorView: View {
    @State private var estimate = Estimate()
    @State private var currentStep = 0
    @State private var selectedClient: Client?
    @State private var createdInvoice: Invoice?
    @State private var showingSuccessAlert = false
    @State private var showingEstimateShareSheet = false
    @State private var estimateShareContent: String = ""
    @ObservedObject private var invoiceManager = InvoiceManager.shared
    @ObservedObject private var estimateManager = EstimateManager.shared
    @Environment(\.dismiss) var dismiss
    
    var estimateCost: Double {
        estimate.items.reduce(0) { total, item in
            let gallonsNeeded = item.squareFootage / (item.surface.baseCoverageRate * item.condition.multiplier)
            
            var mixCost: Double = 0
            let shPrice = 5.0
            let surfactantPrice = 40.0
            
            let shRatio: Double = item.surface == .siding ? 0.1 : 0.3
            let shCost = gallonsNeeded * shRatio * shPrice
            let surfCost = gallonsNeeded * (1.0/128.0) * surfactantPrice
            
            mixCost = shCost + surfCost
            
            // Add selected chemical extra costs distributed? 
            // For now, keep it simple: chemicals are global extra fee
            return total + mixCost
        } + Double(estimate.selectedChemicals.count) * 20.0
    }
    
    var totalPrice: Double {
        let totalSqFt = estimate.items.reduce(0) { $0 + $1.squareFootage }
        
        switch estimate.pricingModel {
        case .perSquareFoot:
            return totalSqFt * estimate.pricePerSqFt
        case .costPlus:
            return (estimate.laborHours * estimate.hourlyRate) + (estimateCost * estimate.materialMarkup)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.slate900.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Header
                    HStack(spacing: 4) {
                        ForEach(0..<4) { step in
                            Rectangle()
                                .fill(step <= currentStep ? Theme.sky500 : Theme.slate800)
                                .frame(height: 4)
                            if step < 3 { Spacer() }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            if currentStep == 0 {
                                JobDetailsStep(estimate: $estimate)
                            } else if currentStep == 1 {
                                ChemicalSelectionStep(estimate: $estimate)
                            } else if currentStep == 2 {
                                PricingStep(estimate: $estimate, calculatedCost: estimateCost)
                            } else {
                                ReviewStep(estimate: estimate, cost: estimateCost, price: totalPrice, selectedClient: $selectedClient)
                            }
                        }
                        .padding()
                    }
                    
                    // Footer Navigation
                    GlassCard {
                        HStack {
                            if currentStep > 0 {
                                Button("Back") { withAnimation { currentStep -= 1 } }
                                    .foregroundColor(Theme.slate400)
                            }
                            Spacer()
                            
                            // Send Estimate button (only on review step)
                            if currentStep == 3 && selectedClient != nil {
                                NeonButton(
                                    title: "Send Estimate",
                                    color: Theme.sky500,
                                    icon: "paperplane.fill"
                                ) {
                                    showingEstimateShareSheet = true
                                }
                                .frame(width: 180)
                            }
                            
                            NeonButton(
                                title: currentStep == 3 ? (selectedClient == nil ? "Select Client" : "Approve & Invoice") : "Next",
                                color: currentStep == 3 ? Theme.emerald500 : Theme.sky500
                            ) {
                                if currentStep < 3 {
                                    withAnimation { currentStep += 1 }
                                } else {
                                    if let client = selectedClient {
                                        // Create invoice with the correct total price
                                        let invoice = invoiceManager.createInvoice(from: estimate, for: client, totalPrice: totalPrice)
                                        createdInvoice = invoice
                                        
                                        // Haptic feedback for success
                                        HapticManager.success()
                                        
                                        // Show success alert
                                        showingSuccessAlert = true
                                    } else {
                                        // Trigger client selection (could be a sheet)
                                        currentStep = 3 // Stay here, but we'll show the picker
                                    }
                                }
                            }
                            .frame(width: 180)
                        }
                    }
                }
            }
            .navigationTitle("New Estimate")
            .alert("Invoice Created!", isPresented: $showingSuccessAlert) {
                if let invoice = createdInvoice {
                    Button("View Invoice") {
                        // Navigate to invoice detail - we'll dismiss and let user navigate from Business Suite
                        dismiss()
                    }
                    Button("Done") {
                        dismiss()
                    }
                } else {
                    Button("OK") {
                        dismiss()
                    }
                }
            } message: {
                if let invoice = createdInvoice {
                    Text("Invoice \(invoice.invoiceNumber) has been created for \(invoice.clientName). Total: $\(String(format: "%.2f", invoice.total))")
                } else {
                    Text("Your invoice has been created successfully.")
                }
            }
            .confirmationDialog("Send Estimate", isPresented: $showingEstimateShareSheet) {
                Button("Text Estimate") {
                    if let client = selectedClient {
                        prepareAndShareEstimate(via: .text, client: client)
                    }
                }
                Button("Email Estimate") {
                    if let client = selectedClient {
                        prepareAndShareEstimate(via: .email, client: client)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose how to send the estimate to \(selectedClient?.name ?? "customer")")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    enum ShareType { case text, email }
    
    private func prepareAndShareEstimate(via type: ShareType, client: Client) {
        let business = BusinessSettings.shared.businessName
        let total = String(format: "$%.2f", totalPrice)
        
        // Generate items list
        let itemsList = estimate.items.map { item in
            let itemTotal = calculateItemPrice(item)
            return "• \(item.displayName) (\(Int(item.squareFootage)) sq ft): $\(String(format: "%.2f", itemTotal))"
        }.joined(separator: "\n")
        
        let content: String
        if type == .text {
            content = """
            Hi \(client.name),
            
            Here's your pressure washing estimate from \(business):
            
            Services:
            \(itemsList)
            
            Total Estimate: \(total)
            
            Please review and let us know your decision. You can approve all services, select specific items, or decline.
            
            Thank you!
            """
        } else {
            content = """
            Estimate for \(client.name)
            
            From: \(business)
            \(BusinessSettings.shared.businessAddress)
            \(BusinessSettings.shared.businessPhone)
            
            SERVICES:
            \(itemsList)
            
            TOTAL ESTIMATE: \(total)
            
            Please review your estimate and let us know your decision:
            
            Options:
            - Approve: Accept the estimate and we'll get started
            - Edit: Choose which services you'd like
            - Decline: Not interested at this time
            
            Thank you for considering \(business)!
            """
        }
        
        // Save estimate to manager
        estimateManager.saveEstimate(estimate, for: client, totalPrice: totalPrice, status: .sent)
        
        // Share the content
        #if os(macOS)
        let picker = NSSharingServicePicker(items: [content])
        picker.show(relativeTo: .zero, of: NSApp.keyWindow?.contentView ?? NSView(), preferredEdge: .minY)
        #else
        estimateShareContent = content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Present share sheet
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                let activityVC = UIActivityViewController(activityItems: [content], applicationActivities: nil)
                rootViewController.present(activityVC, animated: true)
            }
        }
        #endif
        
        // Haptic feedback
        HapticManager.success()
    }
    
    private func calculateItemPrice(_ item: EstimateItem) -> Double {
        switch estimate.pricingModel {
        case .perSquareFoot:
            return item.squareFootage * estimate.pricePerSqFt
        case .costPlus:
            let totalSqFt = estimate.items.reduce(0) { $0 + $1.squareFootage }
            let proportion = totalSqFt > 0 ? item.squareFootage / totalSqFt : 0
            return totalPrice * proportion
        }
    }

// MARK: - Step Views

struct JobDetailsStep: View {
    @Binding var estimate: Estimate
    @State private var showingItemEditor = false
    @State private var editingItem: EstimateItem?
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Job Items")
                    .font(Theme.headingFont)
                    .foregroundColor(.white)
                Spacer()
                Button {
                    editingItem = EstimateItem()
                    showingItemEditor = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Item")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(Theme.sky500)
                }
            }
            
            if estimate.items.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.slate700)
                    Text("Add a service to start estimating")
                        .foregroundColor(Theme.slate500)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .background(Theme.slate800.opacity(0.3))
                .cornerRadius(16)
            } else {
                VStack(spacing: 12) {
                    ForEach(estimate.items) { item in
                        Button {
                            editingItem = item
                            showingItemEditor = true
                        } label: {
                            EstimateItemRow(item: item) {
                                estimate.items.removeAll(where: { $0.id == item.id })
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(isPresented: $showingItemEditor) {
            ItemEditorView(item: Binding(
                get: { editingItem ?? EstimateItem() },
                set: { editingItem = $0 }
            )) { savedItem in
                if let index = estimate.items.firstIndex(where: { $0.id == savedItem.id }) {
                    estimate.items[index] = savedItem
                } else {
                    estimate.items.append(savedItem)
                }
            }
        }
    }
}

struct EstimateItemRow: View {
    let item: EstimateItem
    let onDelete: () -> Void
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                Image(systemName: item.surface.icon)
                    .font(.title2)
                    .foregroundColor(Theme.sky500)
                    .frame(width: 44, height: 44)
                    .background(Theme.sky500.opacity(0.1))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(Theme.bodyFont)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("\(Int(item.squareFootage)) sq ft • \(item.condition.rawValue)")
                        .font(.caption)
                        .foregroundColor(Theme.slate400)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundColor(Theme.slate600)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ItemEditorView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var item: EstimateItem
    var onSave: (EstimateItem) -> Void
    
    @State private var searchText = ""
    @State private var showingSatelliteEstimator = false
    
    var filteredSurfaces: [SurfaceType] {
        SurfaceType.allCases.filter {
            searchText.isEmpty || $0.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Surface Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SELECT SERVICE")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                        
                        TextField("Search services...", text: $searchText)
                            .padding(12)
                            .background(Theme.slate800)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(filteredSurfaces) { surface in
                                SelectionCard(
                                    title: surface.rawValue,
                                    icon: surface.icon,
                                    isSelected: item.surface == surface
                                ) {
                                    item.surface = surface
                                }
                            }
                        }
                    }
                    
                    if item.surface == .custom {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ITEM NAME")
                                .font(Theme.labelFont)
                                .foregroundColor(Theme.slate500)
                            TextField("e.g. Statue Cleaning", text: $item.customName)
                                .padding()
                                .background(Theme.slate800)
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("DIMENSIONS")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                        
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    TextField("500", value: $item.squareFootage, format: .number)
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("sq ft")
                                        .foregroundColor(Theme.slate500)
                                    
                                    Spacer()
                                    
                                    Button {
                                        showingSatelliteEstimator = true
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "map.fill")
                                            Text("Aerial Measure")
                                        }
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Theme.sky500.opacity(0.2))
                                        .foregroundColor(Theme.sky500)
                                        .cornerRadius(4)
                                    }
                                }
                                Slider(value: $item.squareFootage, in: 50...5000, step: 50)
                                    .tint(Theme.sky500)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CONDITION")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                        
                        ForEach(SurfaceCondition.allCases, id: \.self) { condition in
                            Button { item.condition = condition } label: {
                                HStack {
                                    Text(condition.rawValue)
                                        .foregroundColor(item.condition == condition ? .white : Theme.slate300)
                                    Spacer()
                                    if item.condition == condition {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Theme.emerald500)
                                    }
                                }
                                .padding()
                                .background(item.condition == condition ? Theme.emerald500.opacity(0.1) : Theme.slate800)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(item.condition == condition ? Theme.emerald500.opacity(0.5) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                .padding()
            }
            .sheet(isPresented: $showingSatelliteEstimator) {
                SatelliteEstimatorView()
            }
            .background(Theme.slate900)
            .navigationTitle(item.surface == .siding ? "New Service" : "Edit Service")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(item)
                        dismiss()
                    }
                    .foregroundColor(Theme.sky500)
                    .fontWeight(.bold)
                }
            }
        }
    }
}

}
struct ChemicalSelectionStep: View {
    @Binding var estimate: Estimate
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Chemicals")
                .font(Theme.headingFont)
                .foregroundColor(.white)
            
            Text("Select special treatments needed for this job.")
                .foregroundColor(Theme.slate400)
                .multilineTextAlignment(.center)
            
            GlassCard {
                VStack(spacing: 12) {
                    ForEach(ChemicalData.allChemicals.prefix(8)) { chem in // Show top 8 for demo
                        Toggle(isOn: Binding(
                            get: { estimate.selectedChemicals.contains(chem.id) },
                            set: { isActive in
                                if isActive { estimate.selectedChemicals.insert(chem.id) }
                                else { estimate.selectedChemicals.remove(chem.id) }
                            }
                        )) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(chem.name)
                                        .foregroundColor(.white)
                                        .font(Theme.bodyFont)
                                    Text(chem.type.rawValue)
                                        .font(.caption)
                                        .foregroundColor(chem.type.color)
                                }
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Theme.sky500))
                        .padding(.vertical, 4)
                        
                        Divider().background(Theme.slate700)
                    }
                }
            }
        }
    }
}

struct PricingStep: View {
    @Binding var estimate: Estimate
    let calculatedCost: Double
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Pricing Model")
                .font(Theme.headingFont)
                .foregroundColor(.white)
            
            Picker("Model", selection: $estimate.pricingModel) {
                ForEach(PricingModel.allCases, id: \.self) { model in
                    Text(model.rawValue).tag(model)
                }
            }
            .pickerStyle(.segmented)
            
            if estimate.pricingModel == .perSquareFoot {
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("RATE PER SQ FT")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate400)
                        
                        HStack {
                            Text("$")
                                .font(.title)
                                .foregroundColor(Theme.slate400)
                            TextField("0.15", value: $estimate.pricePerSqFt, format: .number)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(Theme.sky500)
                        }
                        
                        Slider(value: $estimate.pricePerSqFt, in: 0.05...1.0, step: 0.01)
                            .tint(Theme.sky500)
                        
                        Text("Market Avg: $0.15 - $0.25")
                            .font(.caption)
                            .foregroundColor(Theme.slate500)
                    }
                }
            } else {
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("LABOR & MATERIALS")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate400)
                        
                        HStack {
                            Text("Hours")
                            Spacer()
                            TextField("4", value: $estimate.laborHours, format: .number)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.white)
                                .frame(width: 80)
                        }
                        
                        HStack {
                            Text("Hourly Rate")
                            Spacer()
                            TextField("150", value: $estimate.hourlyRate, format: .number)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.white)
                                .frame(width: 80)
                        }
                        
                        Divider().background(Theme.slate700)
                        
                        HStack {
                            Text("Material Cost (Est)")
                            Spacer()
                            Text(String(format: "$%.2f", calculatedCost))
                                .foregroundColor(Theme.slate400)
                        }
                        
                        HStack {
                            Text("Markup")
                            Spacer()
                            TextField("1.3", value: $estimate.materialMarkup, format: .number)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.white)
                                .frame(width: 60)
                        }
                    }
                }
            }
        }
    }
}

struct ReviewStep: View {
    let estimate: Estimate
    let cost: Double
    let price: Double
    @Binding var selectedClient: Client?
    
    @State private var showingClientPicker = false
    
    var profit: Double { price - cost }
    var margin: Double { (profit / price) * 100 }
    
    var totalGallons: Double {
        estimate.items.reduce(0) { total, item in
            total + (item.squareFootage / (item.surface.baseCoverageRate * item.condition.multiplier))
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Estimate Review")
                .font(Theme.headingFont)
                .foregroundColor(.white)
            
            GlassCard {
                VStack(spacing: 12) {
                    #if os(macOS)
                    if let data = InvoiceManager.shared.businessSettings.logoData, let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .padding(.bottom, 4)
                    }
                    #else
                    if let data = InvoiceManager.shared.businessSettings.logoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                            .padding(.bottom, 4)
                    }
                    #endif
                    
                    Text("TOTAL ESTIMATE")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                    
                    Text(String(format: "$%.2f", price))
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(Theme.emerald500)
                        .shadow(color: Theme.emerald500.opacity(0.3), radius: 10)
                    
                    Text("\(estimate.items.count) Services • \(Int(estimate.items.reduce(0) { $0 + $1.squareFootage })) Total Sq Ft")
                        .font(.subheadline)
                        .foregroundColor(Theme.slate500)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            
            // Itemized Breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("SERVICES")
                    .font(Theme.labelFont)
                    .foregroundColor(Theme.slate400)
                
                VStack(spacing: 8) {
                    ForEach(estimate.items) { item in
                        HStack {
                            Image(systemName: item.surface.icon)
                                .foregroundColor(Theme.sky500)
                                .font(.caption)
                            Text(item.displayName)
                                .font(.caption.bold())
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(item.squareFootage)) sq ft")
                                .font(.caption2)
                                .foregroundColor(Theme.slate500)
                        }
                        .padding(.vertical, 4)
                        if item.id != estimate.items.last?.id {
                            Divider().background(Theme.slate800)
                        }
                    }
                }
                .padding()
                .background(Theme.slate800.opacity(0.3))
                .cornerRadius(12)
            }
            
            // Client Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("CLIENT")
                    .font(Theme.labelFont)
                    .foregroundColor(Theme.slate400)
                
                Button {
                    showingClientPicker = true
                } label: {
                    GlassCard {
                        HStack {
                            if let client = selectedClient {
                                VStack(alignment: .leading) {
                                    Text(client.name)
                                        .font(Theme.bodyFont)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text(client.address)
                                        .font(.caption)
                                        .foregroundColor(Theme.slate400)
                                }
                            } else {
                                Text("Select a client to proceed to invoice")
                                    .foregroundColor(Theme.slate500)
                                    .italic()
                            }
                            Spacer()
                            Image(systemName: "person.crop.circle.badge.plus")
                                .foregroundColor(Theme.sky500)
                                .font(.title3)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .sheet(isPresented: $showingClientPicker) {
                ClientPicker(selectedClient: $selectedClient)
            }
            
            // Profitability
            HStack(spacing: 12) {
                ResultCard(title: "Est. Cost", value: String(format: "$%.0f", cost), unit: "Materials + Labor", color: Theme.amber500)
                ResultCard(title: "Est. Profit", value: String(format: "$%.0f", profit), unit: String(format: "%.1f%% Margin", margin), color: Theme.sky500)
            }
            
            // Logistics
            GlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("LOGISTICS")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                    
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(Theme.sky500)
                        Text("Mix Needed")
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(format: "%.1f Gallons", totalGallons))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    if !estimate.selectedChemicals.isEmpty {
                        Divider().background(Theme.slate700)
                        Text("Additives:")
                            .font(.caption)
                            .foregroundColor(Theme.slate500)
                        
                        ForEach(Array(estimate.selectedChemicals), id: \.self) { uuid in
                            if let chem = ChemicalData.allChemicals.first(where: { $0.id == uuid }) {
                                Text("• \(chem.name)")
                                    .foregroundColor(Theme.slate400)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ClientPicker: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedClient: Client?
    @State private var searchText = ""
    
    var filteredClients: [Client] {
        Client.mockClients.filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredClients) { client in
                Button {
                    selectedClient = client
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(client.name)
                            .foregroundColor(.white)
                        Text(client.address)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Select Client")
            .searchable(text: $searchText)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct SelectionCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if icon.contains("/") {
                    #if os(macOS)
                    if let nsImage = NSImage(contentsOfFile: icon) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(isSelected ? .white : Theme.sky500)
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(isSelected ? .white : Theme.sky500)
                    }
                    #else
                    if let uiImage = UIImage(contentsOfFile: icon) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(isSelected ? .white : Theme.sky500)
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(isSelected ? .white : Theme.sky500)
                    }
                    #endif
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : Theme.sky500)
                }
                
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(isSelected ? .white : Theme.slate300)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isSelected ? Theme.sky500 : Theme.slate800)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Theme.sky500 : Theme.slate700, lineWidth: 1)
            )
            .shadow(color: isSelected ? Theme.sky500.opacity(0.4) : Color.clear, radius: 8)
        }
        .buttonStyle(.plain)
    }
}
