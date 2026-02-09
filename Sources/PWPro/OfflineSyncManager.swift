import Foundation
import Combine

@MainActor
class OfflineSyncManager: ObservableObject, BaseManager {
    @Published var isLoading = false
    @Published var error: String?
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var pendingSyncCount = 0
    @Published var syncProgress: Double = 0.0
    
    private let storageManager = StorageManager.shared
    private let supabaseManager = SupabaseManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()
    private var syncTimer: Timer?
    
    // Sync queues
    private var clientSyncQueue: [Client] = []
    private var jobSyncQueue: [Job] = []
    private var estimateSyncQueue: [Estimate] = []
    private var invoiceSyncQueue: [Invoice] = []
    private var equipmentSyncQueue: [Equipment] = []
    private var chemicalSyncQueue: [ChemicalInventory] = []
    private var expenseSyncQueue: [Expense] = []
    private var leadSyncQueue: [Lead] = []
    
    init() {
        setupNetworkMonitoring()
        setupPeriodicSync()
        loadPendingSyncData()
    }
    
    deinit {
        syncTimer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .sink { [weak self] isConnected in
                if isConnected && self?.hasPendingSync == true {
                    Task { @MainActor in
                        await self?.syncAllData()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupPeriodicSync() {
        // Sync every 5 minutes when online
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if self?.networkMonitor.isConnected == true {
                    await self?.syncAllData()
                }
            }
        }
    }
    
    private func loadPendingSyncData() {
        // Load any pending sync data from local storage
        loadLocalSyncQueues()
        updatePendingSyncCount()
    }
    
    // MARK: - Sync Operations
    
    func syncAllData() async {
        guard networkMonitor.isConnected else {
            print("Cannot sync: No network connection")
            return
        }
        
        guard !isSyncing else {
            print("Sync already in progress")
            return
        }
        
        isSyncing = true
        isLoading = true
        error = nil
        
        do {
            await withTaskGroup(of: Void.self) { group in
                // Sync clients
                group.addTask {
                    await self.syncClients()
                }
                
                // Sync jobs
                group.addTask {
                    await self.syncJobs()
                }
                
                // Sync estimates
                group.addTask {
                    await self.syncEstimates()
                }
                
                // Sync invoices
                group.addTask {
                    await self.syncInvoices()
                }
                
                // Sync equipment
                group.addTask {
                    await self.syncEquipment()
                }
                
                // Sync chemical inventory
                group.addTask {
                    await self.syncChemicalInventory()
                }
                
                // Sync expenses
                group.addTask {
                    await self.syncExpenses()
                }
                
                // Sync leads
                group.addTask {
                    await self.syncLeads()
                }
            }
            
            // Clear sync queues after successful sync
            clearSyncQueues()
            saveSyncQueues()
            
            lastSyncDate = Date()
            print("All data synced successfully")
            
        } catch {
            self.handleError(error, context: "Data Sync")
        }
        
        isSyncing = false
        isLoading = false
        updatePendingSyncCount()
    }
    
    // MARK: - Individual Sync Methods
    
    private func syncClients() async {
        do {
            // Upload pending changes
            for client in clientSyncQueue {
                if client.id.uuidString.prefix(8) == "local-" {
                    // Create new client
                    _ = try await supabaseManager.insert(client, into: "clients")
                } else {
                    // Update existing client
                    _ = try await supabaseManager.update(client, in: "clients", filter: "id" == client.id.uuidString)
                }
            }
            
            // Download latest data
            let remoteClients = try await supabaseManager.syncClients()
            storageManager.save(remoteClients, to: "clients.json")
            
        } catch {
            print("Failed to sync clients: \(error)")
        }
    }
    
    private func syncJobs() async {
        do {
            // Upload pending changes
            for job in jobSyncQueue {
                if job.id.uuidString.prefix(8) == "local-" {
                    _ = try await supabaseManager.insert(job, into: "jobs")
                } else {
                    _ = try await supabaseManager.update(job, in: "jobs", filter: "id" == job.id.uuidString)
                }
            }
            
            // Download latest data
            let remoteJobs = try await supabaseManager.syncJobs()
            storageManager.save(remoteJobs, to: "jobs.json")
            
        } catch {
            print("Failed to sync jobs: \(error)")
        }
    }
    
    private func syncEstimates() async {
        do {
            // Upload pending changes
            for estimate in estimateSyncQueue {
                if estimate.id.uuidString.prefix(8) == "local-" {
                    _ = try await supabaseManager.insert(estimate, into: "estimates")
                } else {
                    _ = try await supabaseManager.update(estimate, in: "estimates", filter: "id" == estimate.id.uuidString)
                }
            }
            
            // Download latest data
            let remoteEstimates = try await supabaseManager.syncEstimates()
            storageManager.save(remoteEstimates, to: "estimates.json")
            
        } catch {
            print("Failed to sync estimates: \(error)")
        }
    }
    
    private func syncInvoices() async {
        do {
            // Upload pending changes
            for invoice in invoiceSyncQueue {
                if invoice.id.uuidString.prefix(8) == "local-" {
                    _ = try await supabaseManager.insert(invoice, into: "invoices")
                } else {
                    _ = try await supabaseManager.update(invoice, in: "invoices", filter: "id" == invoice.id.uuidString)
                }
            }
            
            // Download latest data
            let remoteInvoices = try await supabaseManager.syncInvoices()
            storageManager.save(remoteInvoices, to: "invoices.json")
            
        } catch {
            print("Failed to sync invoices: \(error)")
        }
    }
    
    private func syncEquipment() async {
        do {
            // Upload pending changes
            for equipment in equipmentSyncQueue {
                if equipment.id.uuidString.prefix(8) == "local-" {
                    _ = try await supabaseManager.insert(equipment, into: "equipment")
                } else {
                    _ = try await supabaseManager.update(equipment, in: "equipment", filter: "id" == equipment.id.uuidString)
                }
            }
            
            // Download latest data
            let remoteEquipment = try await supabaseManager.syncEquipment()
            storageManager.save(remoteEquipment, to: "equipment.json")
            
        } catch {
            print("Failed to sync equipment: \(error)")
        }
    }
    
    private func syncChemicalInventory() async {
        do {
            // Upload pending changes
            for chemical in chemicalSyncQueue {
                if chemical.id.uuidString.prefix(8) == "local-" {
                    _ = try await supabaseManager.insert(chemical, into: "chemical_inventory")
                } else {
                    _ = try await supabaseManager.update(chemical, in: "chemical_inventory", filter: "id" == chemical.id.uuidString)
                }
            }
            
            // Download latest data
            let remoteChemicals = try await supabaseManager.syncChemicalInventory()
            storageManager.save(remoteChemicals, to: "chemical_inventory.json")
            
        } catch {
            print("Failed to sync chemical inventory: \(error)")
        }
    }
    
    private func syncExpenses() async {
        do {
            // Upload pending changes
            for expense in expenseSyncQueue {
                if expense.id.uuidString.prefix(8) == "local-" {
                    _ = try await supabaseManager.insert(expense, into: "expenses")
                } else {
                    _ = try await supabaseManager.update(expense, in: "expenses", filter: "id" == expense.id.uuidString)
                }
            }
            
            // Download latest data
            let remoteExpenses = try await supabaseManager.syncExpenses()
            storageManager.save(remoteExpenses, to: "expenses.json")
            
        } catch {
            print("Failed to sync expenses: \(error)")
        }
    }
    
    private func syncLeads() async {
        do {
            // Upload pending changes
            for lead in leadSyncQueue {
                if lead.id.uuidString.prefix(8) == "local-" {
                    _ = try await supabaseManager.insert(lead, into: "leads")
                } else {
                    _ = try await supabaseManager.update(lead, in: "leads", filter: "id" == lead.id.uuidString)
                }
            }
            
            // Download latest data
            let remoteLeads = try await supabaseManager.syncLeads()
            storageManager.save(remoteLeads, to: "leads.json")
            
        } catch {
            print("Failed to sync leads: \(error)")
        }
    }
    
    // MARK: - Queue Management
    
    func queueClientForSync(_ client: Client) {
        clientSyncQueue.append(client)
        updatePendingSyncCount()
        saveSyncQueues()
    }
    
    func queueJobForSync(_ job: Job) {
        jobSyncQueue.append(job)
        updatePendingSyncCount()
        saveSyncQueues()
    }
    
    func queueEstimateForSync(_ estimate: Estimate) {
        estimateSyncQueue.append(estimate)
        updatePendingSyncCount()
        saveSyncQueues()
    }
    
    func queueInvoiceForSync(_ invoice: Invoice) {
        invoiceSyncQueue.append(invoice)
        updatePendingSyncCount()
        saveSyncQueues()
    }
    
    func queueEquipmentForSync(_ equipment: Equipment) {
        equipmentSyncQueue.append(equipment)
        updatePendingSyncCount()
        saveSyncQueues()
    }
    
    func queueChemicalForSync(_ chemical: ChemicalInventory) {
        chemicalSyncQueue.append(chemical)
        updatePendingSyncCount()
        saveSyncQueues()
    }
    
    func queueExpenseForSync(_ expense: Expense) {
        expenseSyncQueue.append(expense)
        updatePendingSyncCount()
        saveSyncQueues()
    }
    
    func queueLeadForSync(_ lead: Lead) {
        leadSyncQueue.append(lead)
        updatePendingSyncCount()
        saveSyncQueues()
    }
    
    // MARK: - Helper Methods
    
    private func updatePendingSyncCount() {
        pendingSyncCount = clientSyncQueue.count + jobSyncQueue.count + estimateSyncQueue.count +
                         invoiceSyncQueue.count + equipmentSyncQueue.count + chemicalSyncQueue.count +
                         expenseSyncQueue.count + leadSyncQueue.count
    }
    
    private var hasPendingSync: Bool {
        return pendingSyncCount > 0
    }
    
    private func clearSyncQueues() {
        clientSyncQueue.removeAll()
        jobSyncQueue.removeAll()
        estimateSyncQueue.removeAll()
        invoiceSyncQueue.removeAll()
        equipmentSyncQueue.removeAll()
        chemicalSyncQueue.removeAll()
        expenseSyncQueue.removeAll()
        leadSyncQueue.removeAll()
    }
    
    private func saveSyncQueues() {
        // Save sync queues to local storage
        storageManager.save(clientSyncQueue, to: "client_sync_queue.json")
        storageManager.save(jobSyncQueue, to: "job_sync_queue.json")
        storageManager.save(estimateSyncQueue, to: "estimate_sync_queue.json")
        storageManager.save(invoiceSyncQueue, to: "invoice_sync_queue.json")
        storageManager.save(equipmentSyncQueue, to: "equipment_sync_queue.json")
        storageManager.save(chemicalSyncQueue, to: "chemical_sync_queue.json")
        storageManager.save(expenseSyncQueue, to: "expense_sync_queue.json")
        storageManager.save(leadSyncQueue, to: "lead_sync_queue.json")
    }
    
    private func loadLocalSyncQueues() {
        clientSyncQueue = storageManager.load([Client].self, from: "client_sync_queue.json") ?? []
        jobSyncQueue = storageManager.load([Job].self, from: "job_sync_queue.json") ?? []
        estimateSyncQueue = storageManager.load([Estimate].self, from: "estimate_sync_queue.json") ?? []
        invoiceSyncQueue = storageManager.load([Invoice].self, from: "invoice_sync_queue.json") ?? []
        equipmentSyncQueue = storageManager.load([Equipment].self, from: "equipment_sync_queue.json") ?? []
        chemicalSyncQueue = storageManager.load([ChemicalInventory].self, from: "chemical_sync_queue.json") ?? []
        expenseSyncQueue = storageManager.load([Expense].self, from: "expense_sync_queue.json") ?? []
        leadSyncQueue = storageManager.load([Lead].self, from: "lead_sync_queue.json") ?? []
    }
    
    // MARK: - Public Methods
    
    func forceSyncNow() {
        Task { @MainActor in
            await syncAllData()
        }
    }
    
    func clearAllLocalData() {
        storageManager.deleteFile("clients.json")
        storageManager.deleteFile("jobs.json")
        storageManager.deleteFile("estimates.json")
        storageManager.deleteFile("invoices.json")
        storageManager.deleteFile("equipment.json")
        storageManager.deleteFile("chemical_inventory.json")
        storageManager.deleteFile("expenses.json")
        storageManager.deleteFile("leads.json")
        storageManager.deleteFile("client_sync_queue.json")
        storageManager.deleteFile("job_sync_queue.json")
        storageManager.deleteFile("estimate_sync_queue.json")
        storageManager.deleteFile("invoice_sync_queue.json")
        storageManager.deleteFile("equipment_sync_queue.json")
        storageManager.deleteFile("chemical_sync_queue.json")
        storageManager.deleteFile("expense_sync_queue.json")
        storageManager.deleteFile("lead_sync_queue.json")
        
        clearSyncQueues()
        updatePendingSyncCount()
        
        print("All local data cleared")
    }
}

// MARK: - StorageManager Extension

extension StorageManager {
    func deleteFile(_ filename: String) {
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        do {
            try FileManager.default.removeItem(at: url)
            print("Successfully deleted \(filename)")
        } catch {
            print("Failed to delete \(filename): \(error.localizedDescription)")
        }
    }
}