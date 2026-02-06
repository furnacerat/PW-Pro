import Foundation
import SwiftUI

struct ScheduledJob: Identifiable, Codable {
    var id = UUID()
    let invoiceID: UUID?
    let clientName: String
    let clientAddress: String
    var scheduledDate: Date
    var durationHours: Double = 2.0
    var notes: String = ""
    var status: JobStatus = .scheduled
    var reviewSent: Bool = false
    
    // Weather Intelligence (Mock)
    var surfaceType: SurfaceType = .siding
    var windSpeed: Double = 5.0
    var rainChance: Double = 10.0
    
    init(id: UUID = UUID(), 
         invoiceID: UUID? = nil, 
         clientName: String, 
         clientAddress: String, 
         scheduledDate: Date, 
         durationHours: Double = 2.0, 
         notes: String = "", 
         status: JobStatus = .scheduled, 
         reviewSent: Bool = false,
         surfaceType: SurfaceType = .siding,
         windSpeed: Double = 5.0,
         rainChance: Double = 10.0) {
        self.id = id
        self.invoiceID = invoiceID
        self.clientName = clientName
        self.clientAddress = clientAddress
        self.scheduledDate = scheduledDate
        self.durationHours = durationHours
        self.notes = notes
        self.status = status
        self.reviewSent = reviewSent
        self.surfaceType = surfaceType
        self.windSpeed = windSpeed
        self.rainChance = rainChance
    }
    
    enum JobStatus: String, Codable, CaseIterable {
        case scheduled = "Scheduled"
        case inProgress = "In Progress"
        case completed = "Completed"
        case cancelled = "Cancelled"
        
        var color: Color {
            switch self {
            case .scheduled: return Theme.sky500
            case .inProgress: return Theme.amber500
            case .completed: return Theme.emerald500
            case .cancelled: return Theme.red500
            }
        }
    }
}

@MainActor
class SchedulingManager: ObservableObject {
    @Published var jobs: [ScheduledJob] = [] {
        didSet { save() }
    }
    
    private let filename = "jobs.json"
    static let shared = SchedulingManager()
    
    private init() {
        load()
        if jobs.isEmpty {
            // Add some mock jobs for today if nothing loaded
            self.jobs = [
                ScheduledJob(clientName: "Alice Johnson", clientAddress: "123 Maple St, Seattle", scheduledDate: Date(), surfaceType: .roof, windSpeed: 15.0, rainChance: 10.0),
                ScheduledJob(clientName: "Bob Smith", clientAddress: "456 Oak Ave, Bellevue", scheduledDate: Date().addingTimeInterval(7200), surfaceType: .siding, windSpeed: 8.0, rainChance: 45.0)
            ]
            save()
        }
    }
    
    func save() {
        StorageManager.shared.save(jobs, to: filename)
    }
    
    private func load() {
        if let loaded: [ScheduledJob] = StorageManager.shared.load([ScheduledJob].self, from: filename) {
            self.jobs = loaded
        }
    }
    
    func scheduleJob(invoice: Invoice, date: Date) {
        let newJob = ScheduledJob(
            invoiceID: invoice.id,
            clientName: invoice.clientName,
            clientAddress: invoice.clientAddress,
            scheduledDate: date
        )
        jobs.append(newJob)
    }
    
    func jobs(for date: Date) -> [ScheduledJob] {
        jobs.filter { Calendar.current.isDate($0.scheduledDate, inSameDayAs: date) }
    }
}
