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
    var surfaceType: SurfaceType = .sidingVinyl
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
         surfaceType: SurfaceType = .sidingVinyl,
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
    @Published var jobs: [ScheduledJob] = []
    @Published var isLoading = false
    @Published var error: String?
    
    static let shared = SchedulingManager()
    private let supabase = SupabaseManager.shared
    private let jobService: JobService
    
    private init() {
        self.jobService = JobService(client: SupabaseManager.shared.client)
    }
    
    func fetchJobs() async {
        isLoading = true
        error = nil
        
        do {
            let jobDataList = try await jobService.fetchJobs()
            
            // Map Supabase JobData to Local ScheduledJob
            self.jobs = jobDataList.map { jobData in
                ScheduledJob(
                    id: jobData.id,
                    invoiceID: nil, // Not currently in JobData
                    clientName: jobData.clientName,
                    clientAddress: jobData.address ?? "",
                    scheduledDate: jobData.date,
                    durationHours: 2.0, // Default, verify if needed in DB
                    notes: jobData.notes ?? "",
                    status: ScheduledJob.JobStatus(rawValue: jobData.status) ?? .scheduled,
                    reviewSent: false,
                    surfaceType: SurfaceType(rawValue: jobData.serviceType) ?? .sidingVinyl,
                    windSpeed: Double.random(in: 5...15), // Mock weather for now
                    rainChance: Double.random(in: 0...30)
                )
            }
        } catch {
            print("Error fetching jobs: \(error)")
            self.error = "Failed to load jobs: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func scheduleJob(invoice: Invoice, date: Date) {
        Task {
            await addJob(invoice: invoice, date: date)
        }
    }
    
    func addJob(invoice: Invoice, date: Date) async {
        isLoading = true
        
        let newJobId = UUID()
        let status = ScheduledJob.JobStatus.scheduled
        
        // 1. Create Supabase Data Object
        let jobData = JobData(
            id: newJobId,
            userId: supabase.currentUser?.id,
            clientId: nil, // We'd need to link this real Client ID
            clientName: invoice.clientName,
            serviceType: SurfaceType.sidingVinyl.rawValue, // Default or infer from invoice items
            date: date,
            status: status.rawValue,
            address: invoice.clientAddress,
            notes: "Scheduled via App",
            price: invoice.total,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // 2. Optimistic UI Update
        let localJob = ScheduledJob(
            id: newJobId,
            invoiceID: invoice.id,
            clientName: invoice.clientName,
            clientAddress: invoice.clientAddress,
            scheduledDate: date,
            status: status
        )
        self.jobs.append(localJob)
        
        // 3. Persist to Backend
        do {
            try await jobService.insertJob(jobData)
        } catch {
            print("Error creating job: \(error)")
            self.error = "Failed to save job to cloud."
            // Rollback optimistic update?
        }
        
        isLoading = false
    }
    
    func jobs(for date: Date) -> [ScheduledJob] {
        jobs.filter { Calendar.current.isDate($0.scheduledDate, inSameDayAs: date) }
    }
    
    func deleteJob(_ job: ScheduledJob) {
        Task {
            jobs.removeAll { $0.id == job.id }
            do {
                try await jobService.deleteJob(id: job.id)
            } catch {
                print("Error deleting job: \(error)")
                self.error = "Failed to delete job"
                await fetchJobs()
            }
        }
    }
}
