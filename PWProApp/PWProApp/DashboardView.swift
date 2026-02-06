import SwiftUI

struct DashboardView: View {
    @StateObject var scheduler = SchedulingManager.shared
    @StateObject var financialManager = FinancialManager.shared
    @StateObject var invoiceManager = InvoiceManager.shared
    @StateObject var equipmentManager = EquipmentManager.shared
    @StateObject var clientManager = ClientManager.shared
    @State private var showingProfitLoss = false
    @State private var showingInvoiceList = false
    @State private var showingClientList = false
    @State private var showingEstimator = false
    @State private var showingExpenseEntry = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium Industrial Background
                IndustrialBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Branded Header with glow
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PRESSURE WASHING PRO")
                                    .font(.system(size: 14, weight: .bold, design: .serif))
                                    .italic()
                                    .foregroundColor(Theme.sky500)
                                    .glow(color: Theme.sky500, radius: 8)
                                Text("Morning, Harold")
                                    .font(Theme.industrialHeading)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            NavigationLink(destination: SettingsView()) {
                                AppLogoView(size: 44)
                                    .glow(color: Theme.sky500, radius: 12)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Premium Stats with trend indicators
                        HStack(spacing: 16) {
                            let todayJobs = scheduler.jobs(for: Date()).count
                            PremiumStatCard(
                                title: "Jobs Today",
                                value: "\(todayJobs)",
                                change: todayJobs > 5 ? "+\(todayJobs - 5)" : nil,
                                trend: todayJobs > 5 ? .up : .neutral,
                                color: Theme.sky500,
                                icon: "calendar.badge.clock"
                            )
                            
                            let mRev = financialManager.totalRevenue(for: Date(), invoices: invoiceManager.invoices)
                            PremiumStatCard(
                                title: "Month Revenue",
                                value: String(format: "$%.0f", mRev),
                                change: "+12.5%",
                                trend: .up,
                                color: Theme.emerald500,
                                icon: "dollarsign.circle.fill"
                            )
                            .onTapGesture { showingProfitLoss = true }
                        }
                        
                        Text("TODAY'S SCHEDULE")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 10)
                        
                        // Dynamic Job List with Weather Intelligence
                        let todayJobs = scheduler.jobs(for: Date())
                        if todayJobs.isEmpty {
                            GlassCard {
                                VStack(spacing: 16) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 40))
                                        .foregroundColor(Theme.sky500.opacity(0.6))
                                        .glow(color: Theme.sky500, radius: 10)
                                    
                                    Text("No Jobs Today")
                                        .font(Theme.headingFont)
                                        .foregroundColor(.white)
                                    
                                    Text("Book your first job and see your schedule here with weather insights")
                                        .font(.caption)
                                        .foregroundColor(Theme.slate400)
                                        .multilineTextAlignment(.center)
                                    
                                    NavigationLink(destination: CalendarView()) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("View Schedule")
                                        }
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(Theme.sky500)
                                        .cornerRadius(12)
                                        .shadow(color: Theme.sky500.opacity(0.4), radius: 8, y: 4)
                                    }
                                    .buttonStyle(PressableButtonStyle())
                                }
                                .padding(.vertical, 8)
                            }
                        } else {
                            VStack(spacing: 12) {
                                ForEach($scheduler.jobs) { $job in
                                    if Calendar.current.isDate(job.scheduledDate, inSameDayAs: Date()) {
                                        NavigationLink(destination: JobDetailView(job: $job)) {
                                            ScheduledJobRow(job: job)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Equipment Alerts
                        let criticalEquipment = equipmentManager.equipment.filter { $0.status != .healthy }
                        if !criticalEquipment.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("EQUIPMENT ALERTS")
                                    .font(Theme.labelFont)
                                    .foregroundColor(Theme.red500)
                                
                                ForEach(criticalEquipment) { item in
                                    GlassCard {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(item.status == .critical ? Theme.red500 : Theme.amber500)
                                            VStack(alignment: .leading) {
                                                Text(item.name)
                                                    .font(.caption.bold())
                                                    .foregroundColor(.white)
                                                Text(item.status.rawValue)
                                                    .font(.system(size: 8))
                                                    .foregroundColor(Theme.slate400)
                                            }
                                            Spacer()
                                            StatBadge(title: "HEALTH", value: "\(Int(item.healthScore * 100))%", color: item.status == .critical ? Theme.red500 : Theme.amber500)
                                        }
                                    }
                                    .pressableCard()
                                }
                            }
                            .padding(.top, 10)
                        }
                        
                        // Quick Tools Grid
                        Text("QUICK TOOLS")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate500)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 10)
                            
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            NavigationLink(destination: FieldToolsView(selectedTab: 0)) {
                                ToolButton(title: "Chem Calc", icon: "flask.fill")
                            }
                            NavigationLink(destination: SatelliteEstimatorView()) {
                                ToolButton(title: "Surface", icon: "ruler.fill")
                            }
                            NavigationLink(destination: InvoiceListView()) {
                                ToolButton(title: "Invoices", icon: "doc.text.fill")
                            }
                        }
                        
                        Spacer(minLength: 80) // Space for FAB
                    }
                    .padding()
                }
                
                // Overlay Layer (Floating Action Button)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        QuickActionFAB(
                            onNewEstimate: { showingEstimator = true },
                            onNewClient: { showingClientList = true },
                            onNewInvoice: { showingInvoiceList = true },
                            onLogExpense: { showingExpenseEntry = true }
                        )
                    }
                    .padding()
                }
                
                // Removed local Sweep Effect Overlay as it's now global in ContentView
            }
            .sheet(isPresented: $showingProfitLoss) {
                NavigationView {
                    ProfitLossView()
                }
            }
            .sheet(isPresented: $showingExpenseEntry) {
                ExpenseEntryView()
            }
            .navigationDestination(isPresented: $showingInvoiceList) {
                InvoiceListView()
            }
            .navigationDestination(isPresented: $showingClientList) {
                ClientListView(clients: $clientManager.clients)
            }
            .navigationDestination(isPresented: $showingEstimator) {
                EstimatorView()
            }
        }
        .withErrorHandling(error: $equipmentManager.error)
        .task {
            // Parallel Data Loading:
            // We use a TaskGroup to fetch Jobs, Invoices, and Equipment simultaneously.
            // This initializes the dashboard much faster than fetching them sequentially,
            // ensuring the "at-a-glance" numbers appear as quickly as possible.
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await scheduler.fetchJobs() }
                group.addTask { await invoiceManager.fetchInvoices() }
                group.addTask { await equipmentManager.fetchEquipment() }
            }
        }
    }
}

struct BrandingAlert: View {
    var body: some View {
        NavigationLink(destination: BusinessProfileView()) {
            GlassCard {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.amber500.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Theme.amber500)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Finish Your Brand Profile")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Text("Upload a logo to make your invoices look professional.")
                            .font(.caption)
                            .foregroundColor(Theme.slate400)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(Theme.slate500)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct QuickActionFAB: View {
    @State private var isExpanded = false
    
    var onNewEstimate: () -> Void
    var onNewClient: () -> Void
    var onNewInvoice: () -> Void
    var onLogExpense: () -> Void
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            if isExpanded {
                VStack(alignment: .trailing, spacing: 12) {
                    FABAction(title: "New Estimate", icon: "doc.badge.plus", color: Theme.sky500, delay: 0.1) {
                        isExpanded = false
                        onNewEstimate()
                    }
                    FABAction(title: "New Invoice", icon: "doc.text.fill", color: Theme.sky500, delay: 0.08) {
                        isExpanded = false
                        onNewInvoice()
                    }
                    FABAction(title: "New Client", icon: "person.badge.plus", color: Theme.emerald500, delay: 0.05) {
                        isExpanded = false
                        onNewClient()
                    }
                    FABAction(title: "Log Expense", icon: "dollarsign.circle", color: Theme.amber500, delay: 0.0) {
                        isExpanded = false
                        onLogExpense()
                    }
                }
            }
            
            Button {
                HapticManager.medium()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Theme.sky500)
                        .frame(width: 56, height: 56)
                        .shadow(color: Theme.sky500.opacity(0.4), radius: 10, y: 5)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isExpanded ? 45 : 0))
                }
            }
        }
    }
}

struct FABAction: View {
    let title: String
    let icon: String
    let color: Color
    let delay: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.slate800.opacity(0.9))
                    .cornerRadius(8)
                    .shadow(radius: 4)
                
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 44, height: 44)
                        .shadow(color: color.opacity(0.3), radius: 5)
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
            }
        }
        .transition(.scale.combined(with: .move(edge: .bottom)))
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(Theme.slate400)
                Text(value)
                    .font(Theme.headingFont)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct JobWeatherCard: View {
    let job: Job
    
    var analysis: (status: WeatherSafetyStatus, recommendation: String) {
        WeatherEngine.analyze(job: job)
    }
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Time & Address
                HStack {
                    Text(job.scheduledTime)
                        .font(Theme.labelFont)
                        .padding(6)
                        .background(Theme.sky500.opacity(0.2))
                        .foregroundColor(Theme.sky500)
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    Text(job.surfaceType.rawValue)
                        .font(.caption)
                        .foregroundColor(Theme.slate400)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.customerName)
                        .font(Theme.bodyFont)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(job.address)
                        .font(.caption)
                        .foregroundColor(Theme.slate500)
                }
                
                Divider().background(Theme.slate800)
                
                // Weather Info
                HStack(spacing: 20) {
                    WeatherMiniItem(icon: "wind", value: "\(Int(job.windSpeed)) MPH", label: "Wind")
                    WeatherMiniItem(icon: "cloud.rain.fill", value: "\(Int(job.rainChance))%", label: "Rain")
                    Spacer()
                }
                
                // recommendation Badge
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: analysis.status.icon)
                        .foregroundColor(analysis.status.color)
                    Text(analysis.recommendation)
                        .font(.caption)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(analysis.status.color.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(analysis.status.color.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}



struct ToolButton: View {
    let title: String
    let icon: String
    
    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Theme.sky500)
                Text(title)
                    .font(Theme.labelFont)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 10)
        }
    }
}

struct MapPlaceholder: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
            Image(systemName: "map.fill")
                .font(.largeTitle)
                .foregroundColor(Theme.slate400)
        }
    }
}

