import SwiftUI

struct ReferralManagementView: View {
    @StateObject var clientManager = ClientManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Referral Stats
                HStack(spacing: 16) {
                    MetricCard(title: "TOTAL REFERRALS", value: "24", color: Theme.pink500)
                    MetricCard(title: "REWARDS ISSUED", value: "$480", color: Theme.emerald500)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("ACTIVE REFERRAL CODES")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                    
                    ForEach(clientManager.clients.prefix(5)) { client in
                        GlassCard {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(client.name)
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                    Text("Code: \(client.referralCode)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Theme.sky500)
                                }
                                Spacer()
                                StatBadge(title: "USES", value: "\(Int.random(in: 0...3))", color: Theme.slate400)
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("REWARD SYSTEM")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                    
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            RewardRow(title: "Give $20, Get $20", description: "Standard neighbor referral incentive.")
                            Divider().background(Theme.slate700)
                            RewardRow(title: "VIP Multiplier", description: "VIP clients get double rewards for commercial referrals.")
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.slate900)
        .navigationTitle("Referral Program")
    }
}

struct RewardRow: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 8))
                    .foregroundColor(Theme.slate500)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.emerald500)
        }
    }
}

#Preview {
    NavigationStack {
        ReferralManagementView()
    }
}
