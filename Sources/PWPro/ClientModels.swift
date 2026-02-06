import Foundation
import SwiftUI

enum ClientStatus: String, Codable, CaseIterable {
    case lead = "Lead"
    case regular = "Regular"
    case vip = "VIP"
    
    var color: Color {
        switch self {
        case .lead: return Theme.amber500
        case .regular: return Theme.sky500
        case .vip: return Theme.emerald500
        }
    }
}

struct JobRecord: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let amount: Double
    let serviceType: String
    let notes: String
}

struct InteractionLog: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let type: InteractionType
    let notes: String
}

enum InteractionType: String, Codable {
    case call = "Call"
    case email = "Email"
    case onsite = "Onsite Visit"
    case note = "Note"
}

struct Client: Identifiable, Codable {
    var id = UUID()
    let name: String
    let email: String
    let phone: String
    let address: String
    var status: ClientStatus
    var tags: [String]
    var jobHistory: [JobRecord]
    var interactions: [InteractionLog]
    var serviceFrequencyMonths: Int? = 12 // Default to annual
    var referralCode: String = String(UUID().uuidString.prefix(6)).uppercased()
    
    var totalLifetimeValue: Double {
        jobHistory.reduce(0) { $0 + $1.amount }
    }
    
    var lastInteraction: Date? {
        interactions.map { $0.date }.max()
    }
}

// Mock Data for CRM
extension Client {
    static let mockClients: [Client] = [
        Client(
            name: "John Smith",
            email: "john@example.com",
            phone: "(555) 123-4567",
            address: "123 Maple Ave, Springfield",
            status: .regular,
            tags: ["Residential", "Quarterly"],
            jobHistory: [
                JobRecord(date: Date().addingTimeInterval(-86400 * 30), amount: 450.0, serviceType: "House Wash", notes: "Cleaned vinyl siding and gutters."),
                JobRecord(date: Date().addingTimeInterval(-86400 * 180), amount: 300.0, serviceType: "Driveway Cleaning", notes: "Removed oil stains successfully.")
            ],
            interactions: [
                InteractionLog(date: Date().addingTimeInterval(-86400 * 5), type: .call, notes: "Follow up for next month.")
            ]
        ),
        Client(
            name: "Sarah Johnson",
            email: "sarah.j@outlook.com",
            phone: "(555) 987-6543",
            address: "456 Oak Dr, Lakeside",
            status: .vip,
            tags: ["Commercial", "Monthly"],
            jobHistory: [
                JobRecord(date: Date().addingTimeInterval(-86400 * 10), amount: 1200.0, serviceType: "Parking Lot Wash", notes: "Monthly contract service.")
            ],
            interactions: [
                InteractionLog(date: Date().addingTimeInterval(-86400 * 2), type: .onsite, notes: "Measured new annex building.")
            ]
        ),
        Client(
            name: "Michael Brown",
            email: "mbrown77@gmail.com",
            phone: "(555) 555-0199",
            address: "789 Pine Ct, Heights",
            status: .lead,
            tags: ["New Quote", "Roof"],
            jobHistory: [],
            interactions: [
                InteractionLog(date: Date().addingTimeInterval(-3600), type: .email, notes: "Inquiry about roof soft wash.")
            ]
        )
    ]
}
