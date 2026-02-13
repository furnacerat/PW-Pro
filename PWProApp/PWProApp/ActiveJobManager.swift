import SwiftUI

// MARK: - Job Package (Completed Job Record)

struct JobPackage: Codable, Identifiable {
    let id: UUID
    let jobId: UUID
    let clientName: String
    let clientAddress: String
    let invoiceID: UUID?
    let startedAt: Date
    let completedAt: Date
    let checklistCompleted: [String] // Titles of completed checklist items
    let checklistTotal: Int
    let damagePhotoFileNames: [String]
    let damageNotes: [String]
    let beforePhotoFileName: String?
    let afterPhotoFileName: String?
    let sessionNotes: String
    
    var duration: TimeInterval {
        completedAt.timeIntervalSince(startedAt)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    var formattedStartTime: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: startedAt)
    }
    
    var formattedCompletedTime: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: completedAt)
    }
    
    var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d, yyyy"
        return fmt.string(from: completedAt)
    }
}

// MARK: - Active Job Manager

@MainActor
class ActiveJobManager: ObservableObject {
    static let shared = ActiveJobManager()
    
    // Active job state
    @Published var activeJob: ScheduledJob?
    @Published var sessionStartTime: Date?
    
    // Session artifacts
    @Published var checklistState: [String: Bool] = [:]
    @Published var damageRecords: [DamageRecord] = []
    @Published var beforeImage: PlatformImage?
    @Published var afterImage: PlatformImage?
    @Published var sessionNotes: String = ""
    
    // Navigation
    @Published var shouldNavigateToFieldTools = false
    @Published var showReviewPrompt = false
    
    // Completed jobs
    @Published var completedPackages: [JobPackage] = []
    
    var isActive: Bool { activeJob != nil }
    
    var elapsedTime: TimeInterval {
        guard let start = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(start)
    }
    
    var formattedElapsedTime: String {
        let total = Int(elapsedTime)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // ... (existing computed properties) ...

    var jobDisplayName: String {
        guard let job = activeJob else { return "" }
        return job.clientName
    }
    
    var jobDisplayAddress: String {
        guard let job = activeJob else { return "" }
        return job.clientAddress
    }
    
    private let packagesKey = "completedJobPackages"
    
    private init() {
        loadPackages()
    }
    
    // MARK: - Start Job
    
    func startJob(_ job: ScheduledJob) {
        // Reset everything
        checklistState = [:]
        damageRecords = []
        beforeImage = nil
        afterImage = nil
        sessionNotes = ""
        showReviewPrompt = false
        
        // ... (rest of startJob) ...
        
        // Activate
        activeJob = job
        sessionStartTime = Date()
        
        // Update job status
        if let idx = SchedulingManager.shared.jobs.firstIndex(where: { $0.id == job.id }) {
            SchedulingManager.shared.jobs[idx].status = .inProgress
        }
        
        // Trigger navigation
        shouldNavigateToFieldTools = true
        
        HapticManager.heavy()
    }
    
    // MARK: - Complete Job
    
    func completeJob() -> JobPackage? {
        guard let job = activeJob, let startTime = sessionStartTime else { return nil }
        
        // ... (save images logic) ...
        
        // Save before/after images to disk
        var beforeFileName: String?
        var afterFileName: String?
        
        #if os(iOS)
        if let before = beforeImage {
            beforeFileName = DamageRecordStore.saveImage(before)
        }
        if let after = afterImage {
            afterFileName = DamageRecordStore.saveImage(after)
        }
        #endif
        
        // Collect damage photo file names
        let allDamagePhotos = damageRecords.flatMap { $0.imageFileNames }
        let allDamageNotes = damageRecords.map { $0.note }
        
        // Build package
        let completedItems = checklistState.filter { $0.value }.map { $0.key }
        let package = JobPackage(
            id: UUID(),
            jobId: job.id,
            clientName: job.clientName,
            clientAddress: job.clientAddress,
            invoiceID: job.invoiceID,
            startedAt: startTime,
            completedAt: Date(),
            checklistCompleted: completedItems,
            checklistTotal: checklistState.count,
            damagePhotoFileNames: allDamagePhotos,
            damageNotes: allDamageNotes,
            beforePhotoFileName: beforeFileName,
            afterPhotoFileName: afterFileName,
            sessionNotes: sessionNotes
        )
        
        // Save package
        completedPackages.insert(package, at: 0)
        savePackages()
        
        // Update job status to completed
        if let idx = SchedulingManager.shared.jobs.firstIndex(where: { $0.id == job.id }) {
            SchedulingManager.shared.jobs[idx].status = .completed
        }
        
        // Check for review links to trigger prompt
        let settings = InvoiceManager.shared.businessSettings
        if !settings.googleReviewLink.isEmpty || !settings.facebookReviewLink.isEmpty {
            showReviewPrompt = true
        }
        
        // Reset session
        activeJob = nil
        sessionStartTime = nil
        checklistState = [:]
        damageRecords = []
        beforeImage = nil
        afterImage = nil
        sessionNotes = ""
        
        HapticManager.success()
        
        return package
    }
    
    // MARK: - Cancel Job (without completing)
    
    func cancelSession() {
        if let job = activeJob,
           let idx = SchedulingManager.shared.jobs.firstIndex(where: { $0.id == job.id }) {
            SchedulingManager.shared.jobs[idx].status = .scheduled
        }
        
        activeJob = nil
        sessionStartTime = nil
        checklistState = [:]
        damageRecords = []
        beforeImage = nil
        afterImage = nil
        sessionNotes = ""
    }
    
    // MARK: - Add Damage Record (auto-linked)
    
    func addDamageRecord(_ record: DamageRecord) {
        var linkedRecord = record
        if let job = activeJob {
            linkedRecord.jobReference = "\(job.clientName) — \(job.clientAddress)"
        }
        damageRecords.append(linkedRecord)
        
        // Also persist to the global store
        DamageRecordStore.shared.add(linkedRecord)
    }
    
    // MARK: - Persistence
    
    private func savePackages() {
        if let data = try? JSONEncoder().encode(completedPackages) {
            UserDefaults.standard.set(data, forKey: packagesKey)
        }
    }
    
    private func loadPackages() {
        guard let data = UserDefaults.standard.data(forKey: packagesKey),
              let decoded = try? JSONDecoder().decode([JobPackage].self, from: data) else { return }
        completedPackages = decoded
    }
}
