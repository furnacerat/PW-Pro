import SwiftUI

struct AccountingSyncView: View {
    @State private var isSyncing = false
    @State private var lastSync: Date?
    @State private var selectedProvider = "QuickBooks"
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                GlassCard {
                    VStack(spacing: 20) {
                        Image(systemName: "arrow.triangle.2.circlepath.doc.on.clipboard")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.sky500)
                        
                        Text("Connect Your Accounting")
                            .font(Theme.headingFont)
                            .foregroundColor(.white)
                        
                        Text("Automatically sync your invoices and expenses with your professional accounting software.")
                            .font(.caption)
                            .foregroundColor(Theme.slate400)
                            .multilineTextAlignment(.center)
                        
                        Picker("Provider", selection: $selectedProvider) {
                            Text("QuickBooks Online").tag("QuickBooks")
                            Text("Xero").tag("Xero")
                            Text("Sage").tag("Sage")
                        }
                        .pickerStyle(.menu)
                        .padding(8)
                        .background(Theme.slate800)
                        .cornerRadius(12)
                    }
                    .padding()
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("SYNC STATUS")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                    
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(isSyncing ? "Sync in Progress..." : "Ready to Sync")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                
                                if let last = lastSync {
                                    Text("Last synced: \(last.formatted(.dateTime.hour().minute()))")
                                        .font(.system(size: 8))
                                        .foregroundColor(Theme.slate500)
                                } else {
                                    Text("Never synced")
                                        .font(.system(size: 8))
                                        .foregroundColor(Theme.slate500)
                                }
                            }
                            Spacer()
                            if isSyncing {
                                ProgressView()
                                    .tint(Theme.sky500)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.emerald500)
                            }
                        }
                    }
                }
                
                NeonButton(title: isSyncing ? "Syncing..." : "Sync Now", color: Theme.sky500, icon: "arrow.clockwise") {
                    startSync()
                }
                .disabled(isSyncing)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("PENDING ITEMS")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                    
                    HStack {
                        SyncMetric(label: "Invoices", count: 12)
                        SyncMetric(label: "Expenses", count: 4)
                        SyncMetric(label: "Clients", count: 8)
                    }
                }
            }
            .padding()
        }
        .background(Theme.slate900)
        .navigationTitle("Accounting Sync")
    }
    
    private func startSync() {
        isSyncing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isSyncing = false
            lastSync = Date()
        }
    }
}

struct SyncMetric: View {
    let label: String
    let count: Int
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.headline.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Theme.slate500)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.slate800)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        AccountingSyncView()
    }
}
