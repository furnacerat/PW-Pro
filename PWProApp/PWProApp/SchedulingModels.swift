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
    var deployedUserIds: [UUID] = []
    
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
         deployedUserIds: [UUID] = [],
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
        self.deployedUserIds = deployedUserIds
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
                    deployedUserIds: jobData.deployedUserIds ?? [],
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
            deployedUserIds: [],
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
            status: status,
            deployedUserIds: []
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
    
    // MARK: - Deployment Logic
    
    func deployUser(_ userId: UUID, to job: ScheduledJob) {
        Task {
            // 1. Enforce "One active deployment per person"
            // Remove this user from ANY other job they are currently deployed to
            for (index, existingJob) in jobs.enumerated() {
                if existingJob.id != job.id, existingJob.deployedUserIds.contains(userId) {
                    // Remove user from this old job
                    var updatedJob = existingJob
                    updatedJob.deployedUserIds.removeAll { $0 == userId }
                    jobs[index] = updatedJob // Optimistic update
                    
                    // Update backend for old job
                    try? await updateJobDeployment(updatedJob)
                }
            }
            
            // 2. Add user to new job
            guard let index = jobs.firstIndex(where: { $0.id == job.id }) else { return }
            var updatedJob = jobs[index]
            
            // Avoid duplicates
            if !updatedJob.deployedUserIds.contains(userId) {
                updatedJob.deployedUserIds.append(userId)
                jobs[index] = updatedJob // Optimistic update
                
                // 3. Update backend
                do {
                    try await updateJobDeployment(updatedJob)
                    HapticManager.success()
                } catch {
                    print("Error deploying user: \(error)")
                    self.error = "Failed to deploy user."
                    await fetchJobs() // Revert on failure
                }
            }
        }
    }
    
    func undeployUser(_ userId: UUID, from job: ScheduledJob) {
        Task {
            guard let index = jobs.firstIndex(where: { $0.id == job.id }) else { return }
            var updatedJob = jobs[index]
            
            if updatedJob.deployedUserIds.contains(userId) {
                updatedJob.deployedUserIds.removeAll { $0 == userId }
                jobs[index] = updatedJob // Optimistic update
                
                do {
                    try await updateJobDeployment(updatedJob)
                    HapticManager.selection()
                } catch {
                    print("Error undeploying user: \(error)")
                    self.error = "Failed to undeploy user."
                    await fetchJobs()
                }
            }
        }
    }
    
    private func updateJobDeployment(_ job: ScheduledJob) async throws {
        let jobData = JobData(
            id: job.id,
            userId: nil, // Not changing owner
            clientName: job.clientName,
            serviceType: job.surfaceType.rawValue,
            date: job.scheduledDate,
            status: job.status.rawValue,
            address: job.clientAddress,
            notes: job.notes,
            price: nil, // Preserve existing
            deployedUserIds: job.deployedUserIds,
            createdAt: nil,
            updatedAt: Date()
        )
        try await jobService.updateJob(jobData)
    }
}
import SwiftUI
import Supabase

struct UserProfile: Identifiable, Codable {
    let id: UUID
    let email: String
    let fullName: String?
    let role: String? // "Admin", "Technician"
    
    var displayName: String {
        if let name = fullName, !name.isEmpty {
            return name
        }
        return email.components(separatedBy: "@").first ?? "User"
    }
}

@MainActor
class UserManager: ObservableObject {
    static let shared = UserManager()
    private let supabase = SupabaseManager.shared.client
    
    @Published var users: [UserProfile] = []
    @Published var isLoading = false
    
    // Cache for quick lookups
    private var userCache: [UUID: UserProfile] = [:]
    
    // Current user
    var currentUserId: UUID? {
        SupabaseManager.shared.currentUser?.id
    }
    
    init() {
        Task {
            await fetchUsers()
        }
    }
    
    func fetchUsers() async {
        isLoading = true
        do {
            // Try to fetch from a 'profiles' table if it exists
            // If not, we might need a different strategy (like edge functions or just using what we have)
            // For now, we'll try to fetch from 'profiles'
            
            let profiles: [ProfileData] = try await supabase
                .from("profiles")
                .select()
                .execute()
                .value
            
            self.users = profiles.map { profile in
                UserProfile(
                    id: profile.id,
                    email: profile.email ?? "", // Email might not be in public profile
                    fullName: profile.fullName,
                    role: profile.role
                )
            }
            
            // Build cache
            for user in self.users {
                userCache[user.id] = user
            }
            
        } catch {
            print("Error fetching profiles: \(error)")
            // Fallback for demo/dev if table doesn't exist
            if users.isEmpty {
                createMockUsers()
            }
        }
        isLoading = false
    }
    
    func getUser(id: UUID) -> UserProfile? {
        return userCache[id]
    }
    
    func getName(for id: UUID) -> String {
        return getUser(id: id)?.displayName ?? "Unknown User"
    }
    
    private func createMockUsers() {
        // Only for dev/fallback
        guard let currentId = currentUserId else { return }
        
        let me = UserProfile(id: currentId, email: "me@pwpro.com", fullName: "You", role: "Admin")
        let tech1 = UserProfile(id: UUID(), email: "alex@pwpro.com", fullName: "Alex Rivera", role: "Technician")
        let tech2 = UserProfile(id: UUID(), email: "sarah@pwpro.com", fullName: "Sarah Chen", role: "Technician")
        
        self.users = [me, tech1, tech2]
        self.userCache = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
    }
}

// Supabase Data Model
struct ProfileData: Codable {
    let id: UUID
    let email: String?
    let fullName: String?
    let role: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case role
    }
}
