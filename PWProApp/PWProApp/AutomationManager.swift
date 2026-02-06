import Foundation
import SwiftUI

struct WinBackAlert: Identifiable {
    let id = UUID()
    let client: Client
    let suggestedMessage: String
    let dueSince: Date
}

@MainActor
class AutomationManager: ObservableObject {
    @Published var winBackAlerts: [WinBackAlert] = []
    
    static let shared = AutomationManager()
    
    private init() {
        refreshWinBacks()
    }
    
    func refreshWinBacks() {
        let clients = ClientManager.shared.clients
        var alerts: [WinBackAlert] = []
        
        let now = Date()
        
        for client in clients {
            guard let lastJob = client.jobHistory.map({ $0.date }).max(),
                  let frequency = client.serviceFrequencyMonths else { continue }
            
            let nextDueDate = Calendar.current.date(byAdding: .month, value: frequency, to: lastJob) ?? now
            
            if nextDueDate <= now {
                // let monthsSince = Calendar.current.dateComponents([.month], from: nextDueDate, to: now).month ?? 0
                let suggestedMessage = "Hi \(client.name), it's been \(frequency) months since your last wash at \(client.address). You're due for a refresh! Reply 'WASH' to schedule or use your referral code \(client.referralCode) to get 10% off if you refer a neighbor."
                
                alerts.append(WinBackAlert(client: client, suggestedMessage: suggestedMessage, dueSince: nextDueDate))
            }
        }
        
        self.winBackAlerts = alerts.sorted(by: { $0.dueSince < $1.dueSince })
    }
    
    func sendWinBackSMS(alert: WinBackAlert) {
        // Logic similar to JobDetailView SMS sending
        print("Sending Win-Back SMS to \(alert.client.phone): \(alert.suggestedMessage)")
        // In a real app, track that this was sent to avoid duplicates
    }
}
