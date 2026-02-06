import SwiftUI

// MARK: - Models

enum ServiceCategory: String, Codable, CaseIterable {
    case residential = "Residential"
    case commercial = "Commercial"
}

enum ServiceGroup: String, CaseIterable, Identifiable, Codable {
    case houseWash = "House Wash"
    case roofCleaning = "Roof Cleaning"
    case concrete = "Concrete & Driveway"
    case woodRestoration = "Wood Restoration" // Decks & Fences
    case windowsSolar = "Windows & Solar"
    case poolPatio = "Pool & Patio"
    case specialty = "Specialty Services"
    case commercialBuilding = "Commercial Building"
    case commercialFlatwork = "Commercial Flatwork" // Parking, Sidewalks
    case fleetEquipment = "Fleet & Equipment"
    case commercialSpecialty = "Commercial Specialty"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .houseWash: return "house.fill"
        case .roofCleaning: return "skew"
        case .concrete: return "square.grid.2x2.fill"
        case .woodRestoration: return "drop.fill"
        case .windowsSolar: return "sun.max.fill"
        case .poolPatio: return "water.waves"
        case .specialty: return "star.fill"
        case .commercialBuilding: return "building.2.fill"
        case .commercialFlatwork: return "car.fill"
        case .fleetEquipment: return "truck.box.fill"
        case .commercialSpecialty: return "shield.fill"
        }
    }
}

enum SurfaceType: String, CaseIterable, Identifiable, Codable {
    // House Wash
    case sidingVinyl = "Vinyl Siding"
    case sidingBrick = "Brick Siding"
    case sidingStucco = "Stucco"
    case sidingAlum = "Aluminum Siding"
    case sidingWood = "Wood Shake"
    
    // Roof
    case roofShingle = "Shingle Roof"
    case roofTile = "Tile Roof"
    case roofMetal = "Metal Roof"
    case roofSlate = "Slate Roof"
    
    // Concrete
    case concreteStd = "Standard Concrete"
    case drivewayAgg = "Exposed Aggregate"
    case pavers = "Pavers"
    case stampedConcrete = "Stamped Concrete"
    
    // Wood/Fence
    case deckWood = "Wood Deck"
    case deckComp = "Composite Deck"
    case fenceVinyl = "Vinyl Fence"
    case fenceWood = "Wood Fence"
    
    // Windows/Solar
    case windows = "Window Cleaning"
    case solarPanels = "Solar Panels"
    case skylights = "Skylights"
    case gutters = "Gutter Cleaning"
    case gutterGuards = "Gutter Guards"
    
    // Pool/Patio
    case poolDeck = "Pool Deck"
    case screenEnclosure = "Screen Enclosure"
    case patio = "Patio & Walkway"
    
    // Specialty
    case rust = "Rust Removal"
    case efflorescence = "Efflorescence Removal"
    case awningRes = "Awning Cleaning (Res)"
    case garbageCan = "Garbage Can Sanitizing"
    case chimney = "Chimney Washing"
    case graffitiRes = "Graffiti Removal"
    case christmasLights = "Christmas Lights"
    
    // Commercial
    case storefront = "Storefront Wash"
    case parkingLot = "Parking Lot Cleaning"
    case driveThru = "Drive-Thru Lane"
    case gasStation = "Gas Station Canopy"
    case loadingDock = "Loading Dock"
    case breezeway = "Apartment Breezeway"
    case condo = "Condo Exterior"
    case playground = "Playground Sanitizing"
    case bleachers = "Stadium Bleachers"
    case fleet = "Fleet Washing"
    case heavyEquipment = "Heavy Equipment"
    case commercialSidewalk = "Commercial Sidewalk"
    case gumRemoval = "Gum Removal"
    case oilStain = "Oil Stain Remediation"
    case parkingGarage = "Parking Garage Wash"
    case dumpsterPad = "Dumpster Pad"
    case shoppingCenter = "Shopping Center Sidewalks"
    case postConstruction = "Post-Construction Clean"
    case hospital = "Hospital Sanitizing"
    case awningComm = "Commercial Awning"
    
    case custom = "Custom Item"
    
    var id: String { rawValue }
    
    var group: ServiceGroup {
        switch self {
        case .sidingVinyl, .sidingBrick, .sidingStucco, .sidingAlum, .sidingWood: return .houseWash
        case .roofShingle, .roofTile, .roofMetal, .roofSlate: return .roofCleaning
        case .concreteStd, .drivewayAgg, .pavers, .stampedConcrete: return .concrete
        case .deckWood, .deckComp, .fenceVinyl, .fenceWood: return .woodRestoration
        case .windows, .solarPanels, .skylights, .gutters, .gutterGuards: return .windowsSolar
        case .poolDeck, .screenEnclosure, .patio: return .poolPatio
        case .rust, .efflorescence, .awningRes, .garbageCan, .chimney, .graffitiRes, .christmasLights: return .specialty
        
        case .storefront, .breezeway, .condo, .awningComm, .hospital: return .commercialBuilding
        case .parkingLot, .driveThru, .gasStation, .commercialSidewalk, .parkingGarage, .shoppingCenter: return .commercialFlatwork
        case .fleet, .heavyEquipment, .loadingDock, .dumpsterPad: return .fleetEquipment
        case .gumRemoval, .oilStain, .postConstruction, .playground, .bleachers: return .commercialSpecialty
            
        case .custom: return .specialty
        }
    }
    
    var category: ServiceCategory {
        switch group {
        case .commercialBuilding, .commercialFlatwork, .fleetEquipment, .commercialSpecialty: return .commercial
        default: return .residential
        }
    }
    
    var icon: String {
        switch self {
        case .sidingVinyl, .sidingBrick, .sidingStucco, .sidingAlum, .sidingWood: return "house.fill"
        case .roofShingle, .roofTile, .roofMetal, .roofSlate: return "skew"
        case .concreteStd, .drivewayAgg, .pavers, .stampedConcrete: return "square.grid.2x2.fill"
        case .deckWood, .deckComp, .fenceVinyl, .fenceWood: return "drop.fill"
        case .windows, .solarPanels, .skylights, .gutters, .gutterGuards: return "sun.max.fill"
        case .poolDeck, .screenEnclosure, .patio: return "water.waves"
        case .rust: return "star.fill"
        case .efflorescence: return "leaf.fill"
        case .awningRes, .awningComm: return "tent.fill"
        case .garbageCan: return "trash.fill"
        case .chimney: return "smoke.fill"
        case .graffitiRes: return "paintpalette.fill"
        case .christmasLights: return "lightbulb.fill"
        case .storefront: return "building.2.fill"
        case .parkingLot: return "car.fill"
        
        default: return group.icon
        }
    }
    
    var isSystemIcon: Bool {
        !icon.contains("/")
    }
    
    var baseCoverageRate: Double {
        switch group {
        case .houseWash: return 250 // Siding selection
        case .roofCleaning: return 100
        case .concrete: return 150
        case .woodRestoration:
            return self == .fenceVinyl || self == .fenceWood ? 200 : 125 // Fence 200, Deck 125
        case .windowsSolar: return 500
        case .poolPatio: return 125
        case .specialty:
            switch self {
            case .efflorescence: return 75
            default: return 500
            }
        case .commercialBuilding: return 300 // Storefronts
        case .commercialFlatwork: return 400 // Parking lots
        case .fleetEquipment: return 150
        case .commercialSpecialty:
            return self == .gumRemoval || self == .oilStain ? 75 : 150
        }
    }
}

struct EstimateItem: Identifiable, Codable {
    var id = UUID()
    var surface: SurfaceType = .sidingVinyl
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

enum EstimateStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case sent = "Sent"
    case approved = "Approved"
    case rejected = "Rejected"
    case partial = "Partial"
    
    var color: Color {
        switch self {
        case .draft: return Theme.slate500
        case .sent: return Theme.sky500
        case .approved: return Theme.emerald500
        case .rejected: return Theme.red500
        case .partial: return Theme.amber500
        }
    }
    
    var icon: String {
        switch self {
        case .draft: return "doc.text"
        case .sent: return "paperplane.fill"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .partial: return "checkmark.circle.badge.questionmark.fill"
        }
    }
}

struct SavedEstimate: Identifiable, Codable {
    var id = UUID()
    let estimate: Estimate
    let client: Client
    let totalPrice: Double
    var status: EstimateStatus
    let dateSent: Date?
    var dateResponded: Date?
    var customerNotes: String?
    var selectedItemIds: Set<UUID>? // For partial approvals
    
    var displayDate: Date {
        dateResponded ?? dateSent ?? Date()
    }
}

@MainActor
class EstimateManager: ObservableObject {
    static let shared = EstimateManager()
    
    @Published var estimates: [SavedEstimate] = [] {
        didSet {
            save()
        }
    }
    
    private let storageKey = "saved_estimates"
    
    init() {
        load()
    }
    
    func saveEstimate(_ estimate: Estimate, for client: Client, totalPrice: Double, status: EstimateStatus = .sent) {
        let savedEstimate = SavedEstimate(
            estimate: estimate,
            client: client,
            totalPrice: totalPrice,
            status: status,
            dateSent: status == .sent ? Date() : nil,
            dateResponded: nil,
            customerNotes: nil,
            selectedItemIds: nil
        )
        estimates.append(savedEstimate)
    }
    
    func updateStatus(estimateId: UUID, status: EstimateStatus, selectedItemIds: Set<UUID>? = nil, notes: String? = nil) {
        guard let index = estimates.firstIndex(where: { $0.id == estimateId }) else { return }
        
        estimates[index].status = status
        estimates[index].dateResponded = Date()
        estimates[index].selectedItemIds = selectedItemIds
        
        if let notes = notes {
            estimates[index].customerNotes = notes
        }
    }
    
    func getEstimate(id: UUID) -> SavedEstimate? {
        estimates.first { $0.id == id }
    }
    
    func deleteEstimate(id: UUID) {
        estimates.removeAll { $0.id == id }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(estimates) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([SavedEstimate].self, from: data) {
            estimates = decoded
        }
    }
}

// MARK: - View

struct EstimatorView: View {
    @State private var estimate = Estimate()
    @State private var currentStep = 0
    @State private var selectedClient: Client?
    @State private var showingEstimateShareSheet = false
    @State private var estimateShareContent: String = ""
    @ObservedObject private var invoiceManager = InvoiceManager.shared
    @ObservedObject private var estimateManager = EstimateManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showingClientPicker = false
    var estimateCost: Double {
        estimate.items.reduce(0) { total, item in
            let gallonsNeeded = item.squareFootage / (item.surface.baseCoverageRate * item.condition.multiplier)
            
            var mixCost: Double = 0
            let shPrice = 5.0
            let surfactantPrice = 40.0
            
            let shRatio: Double = item.surface.group == .houseWash ? 0.1 : 0.3
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
                                ReviewStep(estimate: estimate, cost: estimateCost, price: totalPrice, selectedClient: $selectedClient, showingClientPicker: $showingClientPicker)
                            }
                        }
                        .padding()
                    }
                    
                    // Footer Navigation
                    VStack(spacing: 0) {
                        GlassCard {
                            HStack {
                                if currentStep > 0 {
                                    Button("Back") { withAnimation { currentStep -= 1 } }
                                        .foregroundColor(Theme.slate400)
                                        .frame(minHeight: 44)
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
                                    .frame(minHeight: 44)
                                }
                                
                                NeonButton(
                                    title: currentStep == 3 ? (selectedClient == nil ? "Select Client" : "Approve & Invoice") : "Next",
                                    color: currentStep == 3 ? Theme.emerald500 : Theme.sky500
                                ) {
                                    if currentStep < 3 {
                                        withAnimation { currentStep += 1 }
                                    } else {
                                        if let client = selectedClient {
                                            invoiceManager.createInvoice(from: estimate, for: client)
                                            dismiss()
                                        } else {
                                            // Trigger client selection
                                            currentStep = 3 
                                            showingClientPicker = true
                                        }
                                    }
                                }
                                .frame(width: 180)
                                .frame(minHeight: 44)
                            }
                        }
                    }
                    .background(Theme.slate900)
                }
            }
            .navigationTitle("New Estimate")
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
            .sheet(isPresented: $showingClientPicker) {
                ClientPicker(selectedClient: $selectedClient)
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
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            let activityVC = UIActivityViewController(activityItems: [content], applicationActivities: nil)
            rootViewController.present(activityVC, animated: true)
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
}

// MARK: - Estimates Management Views

struct EstimatesListView: View {
    @ObservedObject private var estimateManager = EstimateManager.shared
    @ObservedObject private var invoiceManager = InvoiceManager.shared
    @State private var selectedEstimate: SavedEstimate?
    @State private var showingStatusUpdate = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if estimateManager.estimates.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.slate600)
                        
                        Text("No Estimates Yet")
                            .font(Theme.headingFont)
                            .foregroundColor(.white)
                        
                        Text("Estimates you send to customers will appear here")
                            .font(.caption)
                            .foregroundColor(Theme.slate500)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    ForEach(estimateManager.estimates.sorted(by: { $0.displayDate > $1.displayDate })) { savedEstimate in
                        EstimateCard(estimate: savedEstimate) {
                            selectedEstimate = savedEstimate
                            showingStatusUpdate = true
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.slate900)
        .navigationTitle("Sent Estimates")
        .sheet(isPresented: $showingStatusUpdate) {
            if let estimate = selectedEstimate {
                EstimateStatusSheet(estimate: estimate)
            }
        }
    }
}

struct EstimateCard: View {
    let estimate: SavedEstimate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(estimate.client.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if let dateSent = estimate.dateSent {
                                Text("Sent \(dateSent.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2)
                                    .foregroundColor(Theme.slate500)
                            }
                        }
                        
                        Spacer()
                        
                        // Status badge
                        HStack(spacing: 4) {
                            Image(systemName: estimate.status.icon)
                            Text(estimate.status.rawValue)
                                .font(.caption.bold())
                        }
                        .foregroundColor(estimate.status.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(estimate.status.color.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Divider().background(Theme.slate700)
                    
                    // Items summary
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SERVICES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.slate500)
                        
                        ForEach(estimate.estimate.items.prefix(3)) { item in
                            Text("• \(item.displayName)")
                                .font(.caption)
                                .foregroundColor(Theme.slate400)
                        }
                        
                        if estimate.estimate.items.count > 3 {
                            Text("+ \(estimate.estimate.items.count - 3) more")
                                .font(.caption)
                                .foregroundColor(Theme.slate500)
                        }
                    }
                    
                    Divider().background(Theme.slate700)
                    
                    // Total
                    HStack {
                        Text("TOTAL")
                            .font(.caption.bold())
                            .foregroundColor(Theme.slate500)
                        Spacer()
                        Text(String(format: "$%.2f", estimate.totalPrice))
                            .font(.title3.bold())
                            .foregroundColor(Theme.emerald500)
                    }
                    
                    // Customer notes (if any)
                    if let notes = estimate.customerNotes, !notes.isEmpty {
                        Divider().background(Theme.slate700)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NOTES")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.slate500)
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(Theme.slate400)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct EstimateStatusSheet: View {
    let estimate: SavedEstimate
    @ObservedObject private var estimateManager = EstimateManager.shared
    @ObservedObject private var invoiceManager = InvoiceManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedStatus: EstimateStatus
    @State private var customerNotes: String = ""
    @State private var selectedItems: Set<UUID>
    @State private var showingInvoiceSuccess = false
    
    init(estimate: SavedEstimate) {
        self.estimate = estimate
        _selectedStatus = State(initialValue: estimate.status)
        _customerNotes = State(initialValue: estimate.customerNotes ?? "")
        _selectedItems = State(initialValue: estimate.selectedItemIds ?? Set(estimate.estimate.items.map { $0.id }))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Estimate info
                    GlassCard {
                        VStack(spacing: 12) {
                            HStack {
                                Text("CLIENT")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.slate500)
                                Spacer()
                                Text(estimate.client.name)
                                    .foregroundColor(.white)
                            }
                            
                            Divider().background(Theme.slate700)
                            
                            HStack {
                                Text("TOTAL")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.slate500)
                                Spacer()
                                Text(String(format: "$%.2f", estimate.totalPrice))
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.emerald500)
                            }
                        }
                    }
                    
                    // Status selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("UPDATE STATUS")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                        
                        VStack(spacing: 8) {
                            ForEach([EstimateStatus.approved, .partial, .rejected], id: \.self) { status in
                                Button {
                                    selectedStatus = status
                                    HapticManager.selection()
                                } label: {
                                    HStack {
                                        Image(systemName: status.icon)
                                            .foregroundColor(selectedStatus == status ? status.color : Theme.slate500)
                                        
                                        Text(status.rawValue)
                                            .foregroundColor(selectedStatus == status ? .white : Theme.slate400)
                                        
                                        Spacer()
                                        
                                        if selectedStatus == status {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(status.color)
                                        }
                                    }
                                    .padding()
                                    .background(selectedStatus == status ? status.color.opacity(0.1) : Theme.slate800)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedStatus == status ? status.color : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Item selection (for partial approval)
                    if selectedStatus == .partial {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SELECT SERVICES")
                                .font(Theme.labelFont)
                                .foregroundColor(Theme.slate500)
                            
                            GlassCard {
                                VStack(spacing: 8) {
                                    ForEach(estimate.estimate.items) { item in
                                        Toggle(isOn: Binding(
                                            get: { selectedItems.contains(item.id) },
                                            set: { isSelected in
                                                if isSelected {
                                                    selectedItems.insert(item.id)
                                                } else {
                                                    selectedItems.remove(item.id)
                                                }
                                            }
                                        )) {
                                            Text(item.displayName)
                                                .foregroundColor(.white)
                                        }
                                        .tint(Theme.emerald500)
                                        
                                        if item.id != estimate.estimate.items.last?.id {
                                            Divider().background(Theme.slate700)
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Customer notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTES (OPTIONAL)")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                        
                        TextEditor(text: $customerNotes)
                            .frame(height: 100)
                            .padding(8)
                            .background(Theme.slate800)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        if selectedStatus == .approved || selectedStatus == .partial {
                            Button {
                                createInvoiceFromEstimate()
                            } label: {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                    Text("Update & Create Invoice")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.emerald500)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Theme.emerald500.opacity(0.3), radius: 10, y: 5)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                updateEstimateStatus()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Update Status")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.sky500)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Theme.sky500.opacity(0.3), radius: 10, y: 5)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .background(Theme.slate900)
            .navigationTitle("Update Estimate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Invoice Created!", isPresented: $showingInvoiceSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Invoice has been created successfully from this estimate.")
            }
        }
    }
    
    private func updateEstimateStatus() {
        estimateManager.updateStatus(
            estimateId: estimate.id,
            status: selectedStatus,
            selectedItemIds: selectedStatus == .partial ? selectedItems : nil,
            notes: customerNotes.isEmpty ? nil : customerNotes
        )
        HapticManager.success()
        dismiss()
    }
    
    private func createInvoiceFromEstimate() {
        // Create a modified estimate with only selected items if partial
        var estimateToUse = estimate.estimate
        if selectedStatus == .partial {
            estimateToUse.items = estimate.estimate.items.filter { selectedItems.contains($0.id) }
        }
        
        // Calculate total for selected items
        let totalPrice = estimateToUse.items.reduce(0.0) { total, item in
            switch estimate.estimate.pricingModel {
            case .perSquareFoot:
                return total + (item.squareFootage * estimateToUse.pricePerSqFt)
            case .costPlus:
                let totalSqFt = estimateToUse.items.reduce(0) { $0 + $1.squareFootage }
                let proportion = totalSqFt > 0 ? item.squareFootage / totalSqFt : 0
                return total + (estimate.totalPrice * proportion)
            }
        }
        
        // Create invoice
        invoiceManager.createInvoice(from: estimateToUse, for: estimate.client, totalPrice: totalPrice)
        
        // Update estimate status
        estimateManager.updateStatus(
            estimateId: estimate.id,
            status: selectedStatus,
            selectedItemIds: selectedStatus == .partial ? selectedItems : nil,
            notes: customerNotes.isEmpty ? nil : customerNotes
        )
        
        HapticManager.success()
        showingInvoiceSuccess = true
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
                if item.surface.icon.contains("/") {
                    #if os(macOS)
                    if let nsImage = NSImage(contentsOfFile: item.surface.icon) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .cornerRadius(12)
                    } else {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(Theme.sky500)
                            .frame(width: 44, height: 44)
                            .background(Theme.sky500.opacity(0.1))
                            .cornerRadius(12)
                    }
                    #else
                    if let uiImage = UIImage(contentsOfFile: item.surface.icon) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .cornerRadius(12)
                    } else {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(Theme.sky500)
                            .frame(width: 44, height: 44)
                            .background(Theme.sky500.opacity(0.1))
                            .cornerRadius(12)
                    }
                    #endif
                } else {
                    Image(systemName: item.surface.icon)
                        .font(.title2)
                        .foregroundColor(Theme.sky500)
                        .frame(width: 44, height: 44)
                        .background(Theme.sky500.opacity(0.1))
                        .cornerRadius(12)
                }
                
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
                        .font(.title3)
                        .foregroundColor(Theme.slate600)
                        .frame(width: 44, height: 44)
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
    @State private var selectedCategory: ServiceCategory = .residential
    @State private var selectedGroup: ServiceGroup? // nil = showing groups, set = showing variants
    @State private var showingSatelliteEstimator = false
    @State private var showingScanner = false
    
    // Filtered Groups based on category
    var filteredGroups: [ServiceGroup] {
        // Get all unique groups available in the selected category
        let availableGroups = Set(SurfaceType.allCases
            .filter { $0.category == selectedCategory }
            .map { $0.group })
            
        return ServiceGroup.allCases.filter { group in
            // Must be in category
            guard availableGroups.contains(group) else { return false }
            
            // Search logic: Match group name OR any of its contained variants
            if !searchText.isEmpty {
                let variants = SurfaceType.allCases.filter { $0.group == group }
                let groupMatches = group.rawValue.localizedCaseInsensitiveContains(searchText)
                let variantMatches = variants.contains { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
                return groupMatches || variantMatches
            }
            return true
        }
    }
    
    // Filtered Variants based on selected group
    var filteredVariants: [SurfaceType] {
        guard let group = selectedGroup else { return [] }
        return SurfaceType.allCases.filter { surface in
            surface.group == group &&
            surface != .custom && // handled properly
            (searchText.isEmpty || surface.rawValue.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    serviceSelectionHeader
                    if selectedGroup == nil {
                        categorySwitcher
                    } else {
                        breadcrumbTitle
                    }
                    searchBar
                    serviceSelectionGrid
                    if item.surface == .custom {
                        customItemNameInput
                    }
                    dimensionsEditor
                    conditionSelector
                }
                .padding()
            }
            .sheet(isPresented: $showingSatelliteEstimator) {
                SatelliteEstimatorView()
            }
            .sheet(isPresented: $showingScanner) {
                SmartCameraView(estimatedSqFt: $item.squareFootage, identifiedSurface: $item.surface)
            }
            .background(Theme.slate900)
            .navigationTitle(item.surface == .sidingVinyl ? "New Service" : "Edit Service")
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

    private var serviceSelectionHeader: some View {
        HStack {
            Text("SELECT SERVICE")
                .font(Theme.labelFont)
                .foregroundColor(Theme.slate500)
            Spacer()
            
            Button {
                showingScanner = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "camera.viewfinder")
                    Text("AI Scan")
                }
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.sky500.opacity(0.1))
                .foregroundColor(Theme.sky500)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.sky500.opacity(0.3), lineWidth: 1)
                )
            }
            
            if selectedGroup != nil {
                Button("Change Group") {
                    withAnimation { selectedGroup = nil }
                }
                .font(.caption.bold())
                .foregroundColor(Theme.sky500)
            }
        }
    }

    private var categorySwitcher: some View {
        Picker("Category", selection: $selectedCategory) {
            ForEach(ServiceCategory.allCases, id: \.self) { category in
                Text(category.rawValue).tag(category)
            }
        }
        .pickerStyle(.segmented)
        .padding(.bottom, 8)
    }

    private var breadcrumbTitle: some View {
        HStack(spacing: 8) {
            Image(systemName: "chevron.right")
                .foregroundColor(Theme.slate500)
            Text(selectedGroup?.rawValue ?? "")
                .font(Theme.headingFont)
                .foregroundColor(.white)
        }
        .padding(.bottom, 8)
    }

    private var searchBar: some View {
        TextField("Search services...", text: $searchText)
            .padding(12)
            .background(Theme.slate800)
            .cornerRadius(12)
            .foregroundColor(.white)
    }

    private var serviceSelectionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if selectedGroup != nil {
                ForEach(filteredVariants) { surface in
                    SelectionCard(
                        title: surface.rawValue,
                        icon: surface.icon,
                        isSelected: item.surface == surface
                    ) {
                        item.surface = surface
                    }
                }
            } else {
                ForEach(filteredGroups) { group in
                    SelectionCard(
                        title: group.rawValue,
                        icon: group.icon,
                        isSelected: false
                    ) {
                        withAnimation {
                            selectedGroup = group
                        }
                    }
                }
                
                if selectedCategory == .residential {
                    SelectionCard(
                        title: "Custom Item",
                        icon: "plus.circle.fill",
                        isSelected: item.surface == .custom
                    ) {
                        item.surface = .custom
                    }
                }
            }
        }
    }

    private var customItemNameInput: some View {
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

    private var dimensionsEditor: some View {
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
    }

    private var conditionSelector: some View {
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
    @Binding var showingClientPicker: Bool
    
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
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(isSelected ? .white : Theme.sky500)
                    }
                    #else
                    if let uiImage = UIImage(contentsOfFile: icon) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
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
