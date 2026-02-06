import SwiftUI

struct BusinessSuiteView: View {
    @StateObject var clientManager = ClientManager.shared
    @StateObject var financialManager = FinancialManager.shared
    @StateObject var invoiceManager = InvoiceManager.shared
    @StateObject var automationManager = AutomationManager.shared
    
    var activeLeadsCount: Int {
        clientManager.clients.filter { $0.status == .lead }.count
    }
    
    var totalRevenue: Double {
        financialManager.totalRevenue(for: Date(), invoices: invoiceManager.invoices, isLifetime: true)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Metrics
                    HStack(spacing: 16) {
                        MetricCard(title: "TOTAL REVENUE", value: "$\(Int(totalRevenue))", color: Theme.emerald500)
                        MetricCard(title: "ACTIVE LEADS", value: "\(activeLeadsCount)", color: Theme.amber500)
                    }
                    
                    // CRM Quick Links
                    VStack(alignment: .leading, spacing: 12) {
                        Text("QUICK ACTIONS")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate400)
                        
                        NavigationLink(destination: LeadPipelineView(clients: $clientManager.clients)) {
                            MenuButton(title: "Lead Pipeline", icon: "arrow.triangle.pull", color: Theme.amber500)
                        }
                        
                        NavigationLink(destination: ClientListView(clients: $clientManager.clients)) {
                            MenuButton(title: "Client Database", icon: "person.2.fill", color: Theme.sky500)
                        }
                        
                        NavigationLink(destination: InvoiceListView()) {
                            MenuButton(title: "Invoices", icon: "doc.text.fill", color: Theme.emerald500)
                        }
                        
                        NavigationLink(destination: PaymentProviderSettingsView()) {
                            MenuButton(title: "Payment Settings", icon: "creditcard.fill", color: Theme.purple500)
                        }
                        
                        NavigationLink(destination: InstantQuoteWidgetView()) {
                            MenuButton(title: "Instant Quote Widget", icon: "window.badge.plus", color: Theme.pink500)
                        }
                        
                        NavigationLink(destination: ReferralManagementView()) {
                            MenuButton(title: "Referral Program", icon: "heart.fill", color: Theme.red500)
                        }
                        
                        NavigationLink(destination: AccountingSyncView()) {
                            MenuButton(title: "Accounting Sync", icon: "arrow.triangle.2.circlepath", color: Theme.sky500)
                        }
                        
                        NavigationLink(destination: ProfitLossView()) {
                            MenuButton(title: "Profit & Loss", icon: "chart.pie.fill", color: Theme.red500)
                        }
                    }
                    
                    // Win-Back Alerts
                    if !automationManager.winBackAlerts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("LOYALTY AUTOMATION")
                                .font(Theme.labelFont)
                                .foregroundColor(Theme.sky500)
                            
                            ForEach(automationManager.winBackAlerts.prefix(3)) { alert in
                                GlassCard {
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            Text(alert.client.name)
                                                .font(.caption.bold())
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text("DUE FOR SERVICE")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(Theme.sky500)
                                        }
                                        
                                        Text(alert.suggestedMessage)
                                            .font(.system(size: 10))
                                            .foregroundColor(Theme.slate400)
                                            .lineLimit(2)
                                        
                                        HStack {
                                            NeonButton(title: "Send SMS", color: Theme.sky500) {
                                                automationManager.sendWinBackSMS(alert: alert)
                                            }
                                            .frame(height: 30)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Revenue Chart (Existing but refined)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WEEKLY PERFORMANCE")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate400)
                        
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("$12,500")
                                    .font(Theme.headingFont)
                                    .foregroundColor(.white)
                                
                                HStack(alignment: .bottom, spacing: 8) {
                                    ForEach(0..<7) { _ in
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(LinearGradient(colors: [Theme.sky500, Theme.sky700], startPoint: .top, endPoint: .bottom))
                                            .frame(height: CGFloat.random(in: 30...100))
                                    }
                                }
                                .frame(height: 120)
                            }
                        }
                    }
                    
                    // Recent Invoices (Existing)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RECENT INVOICES")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate400)
                        
                        InvoiceRow(client: "Acme Corp", amount: "$1,500", status: "PAID", statusColor: Theme.emerald500)
                        InvoiceRow(client: "TechSolutions Inc", amount: "$2,850", status: "PENDING", statusColor: Theme.amber500)
                    }
                }
                .padding()
            }
            .background(Theme.slate900)
            .navigationTitle("Business Suite")
            .toolbarColorScheme(.dark)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.slate400)
                Text(value)
                    .font(Theme.headingFont)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        GlassCard {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 32)
                Text(title)
                    .font(Theme.bodyFont)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.slate500)
            }
        }
    }
}

struct InvoiceRow: View {
    let client: String
    let amount: String
    let status: String
    let statusColor: Color
    
    var body: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading) {
                    Text(client)
                        .font(Theme.bodyFont)
                        .foregroundColor(.white)
                    Text(amount)
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                }
                Spacer()
                Text(status)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(statusColor.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}
