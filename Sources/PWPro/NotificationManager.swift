import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var scheduledNotifications: [UNNotificationRequest] = []
    
    private init() {
        checkAuthorizationStatus()
        loadScheduledNotifications()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            
            await MainActor.run {
                self.isAuthorized = granted
                self.authorizationStatus = granted ? .authorized : .denied
            }
            
            if granted {
                print("Notification authorization granted")
                await registerForRemoteNotifications()
            } else {
                print("Notification authorization denied")
            }
            
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            await MainActor.run {
                self.authorizationStatus = .denied
            }
            return false
        }
    }
    
    private func registerForRemoteNotifications() async {
        await UIApplication.shared.registerForRemoteNotifications()
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleJobReminder(for job: Job, reminderTime: TimeInterval = 3600) async {
        guard let jobId = job.id as? UUID,
              let scheduledAt = job.scheduledAt else {
            print("Cannot schedule reminder: invalid job data")
            return
        }
        
        // Calculate reminder time (scheduledAt - reminderTime)
        let reminderDate = scheduledAt.addingTimeInterval(-reminderTime)
        
        // Don't schedule if reminder time is in the past
        if reminderDate <= Date() {
            print("Cannot schedule reminder: time is in the past")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Job Reminder"
        content.body = "Your job \"\(job.title)\" is scheduled in \(Int(reminderTime / 3600)) hour(s)"
        content.sound = .default
        content.userInfo = [
            "type": "job_reminder",
            "jobId": jobId.uuidString,
            "title": job.title
        ]
        
        // Add actions
        let viewAction = UNNotificationAction(
            identifier: "VIEW_JOB",
            title: "View Job",
            options: [.foreground]
        )
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_JOB",
            title: "Complete Job",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "JOB_REMINDER",
            actions: [viewAction, completeAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "JOB_REMINDER"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminderDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "job_reminder_\(jobId.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled job reminder for \(job.title) at \(reminderDate)")
            await loadScheduledNotifications()
        } catch {
            print("Error scheduling job reminder: \(error)")
        }
    }
    
    func scheduleEstimateFollowUp(for estimate: Estimate, followUpDate: Date) async {
        guard let estimateId = estimate.id as? UUID else {
            print("Cannot schedule follow-up: invalid estimate data")
            return
        }
        
        // Don't schedule if follow-up date is in the past
        if followUpDate <= Date() {
            print("Cannot schedule follow-up: date is in the past")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Estimate Follow-up"
        content.body = "Follow up with client about estimate \"\(estimate.title)\""
        content.sound = .default
        content.userInfo = [
            "type": "estimate_followup",
            "estimateId": estimateId.uuidString,
            "title": estimate.title
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: followUpDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "estimate_followup_\(estimateId.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled estimate follow-up for \(estimate.title) at \(followUpDate)")
            await loadScheduledNotifications()
        } catch {
            print("Error scheduling estimate follow-up: \(error)")
        }
    }
    
    func scheduleInvoiceReminder(for invoice: Invoice, reminderDate: Date) async {
        guard let invoiceId = invoice.id as? UUID else {
            print("Cannot schedule invoice reminder: invalid invoice data")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Invoice Reminder"
        content.body = "Invoice \(invoice.invoiceNumber) payment is due"
        content.sound = .default
        content.userInfo = [
            "type": "invoice_reminder",
            "invoiceId": invoiceId.uuidString,
            "invoiceNumber": invoice.invoiceNumber
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminderDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "invoice_reminder_\(invoiceId.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled invoice reminder for \(invoice.invoiceNumber) at \(reminderDate)")
            await loadScheduledNotifications()
        } catch {
            print("Error scheduling invoice reminder: \(error)")
        }
    }
    
    func scheduleEquipmentMaintenance(for equipment: Equipment, maintenanceDate: Date) async {
        guard let equipmentId = equipment.id as? UUID else {
            print("Cannot schedule maintenance reminder: invalid equipment data")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Equipment Maintenance"
        content.body = "Maintenance due for \(equipment.name)"
        content.sound = .default
        content.userInfo = [
            "type": "equipment_maintenance",
            "equipmentId": equipmentId.uuidString,
            "equipmentName": equipment.name
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: maintenanceDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "equipment_maintenance_\(equipmentId.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled equipment maintenance for \(equipment.name) at \(maintenanceDate)")
            await loadScheduledNotifications()
        } catch {
            print("Error scheduling equipment maintenance: \(error)")
        }
    }
    
    func scheduleLeadFollowUp(for lead: Lead, followUpDate: Date) async {
        guard let leadId = lead.id as? UUID else {
            print("Cannot schedule lead follow-up: invalid lead data")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Lead Follow-up"
        content.body = "Follow up with lead: \(lead.source ?? "Unknown")"
        content.sound = .default
        content.userInfo = [
            "type": "lead_followup",
            "leadId": leadId.uuidString,
            "source": lead.source ?? ""
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: followUpDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "lead_followup_\(leadId.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled lead follow-up at \(followUpDate)")
            await loadScheduledNotifications()
        } catch {
            print("Error scheduling lead follow-up: \(error)")
        }
    }
    
    func sendImmediateNotification(title: String, body: String, userInfo: [String: Any] = [:]) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate notification
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Sent immediate notification: \(title)")
        } catch {
            print("Error sending immediate notification: \(error)")
        }
    }
    
    // MARK: - Notification Management
    
    func cancelNotification(withIdentifier identifier: String) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        await loadScheduledNotifications()
        print("Cancelled notification: \(identifier)")
    }
    
    func cancelAllNotifications() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        await loadScheduledNotifications()
        print("Cancelled all notifications")
    }
    
    func cancelNotifications(for job: Job) async {
        guard let jobId = job.id as? UUID else { return }
        
        let identifier = "job_reminder_\(jobId.uuidString)"
        await cancelNotification(withIdentifier: identifier)
    }
    
    func cancelNotifications(for estimate: Estimate) async {
        guard let estimateId = estimate.id as? UUID else { return }
        
        let identifier = "estimate_followup_\(estimateId.uuidString)"
        await cancelNotification(withIdentifier: identifier)
    }
    
    func cancelNotifications(for invoice: Invoice) async {
        guard let invoiceId = invoice.id as? UUID else { return }
        
        let identifier = "invoice_reminder_\(invoiceId.uuidString)"
        await cancelNotification(withIdentifier: identifier)
    }
    
    func cancelNotifications(for equipment: Equipment) async {
        guard let equipmentId = equipment.id as? UUID else { return }
        
        let identifier = "equipment_maintenance_\(equipmentId.uuidString)"
        await cancelNotification(withIdentifier: identifier)
    }
    
    func cancelNotifications(for lead: Lead) async {
        guard let leadId = lead.id as? UUID else { return }
        
        let identifier = "lead_followup_\(leadId.uuidString)"
        await cancelNotification(withIdentifier: identifier)
    }
    
    private func loadScheduledNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        await MainActor.run {
            self.scheduledNotifications = requests
        }
    }
    
    // MARK: - Notification Settings
    
    func scheduleDefaultReminders(for job: Job) async {
        // Schedule reminders for 24 hours and 1 hour before
        await scheduleJobReminder(for: job, reminderTime: 24 * 3600) // 24 hours
        await scheduleJobReminder(for: job, reminderTime: 3600)     // 1 hour
    }
    
    func scheduleDailySummary(at time: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Daily Summary"
        content.body = "Check your jobs and tasks for today"
        content.sound = .default
        content.userInfo = ["type": "daily_summary"]
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_summary",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled daily summary at \(time)")
            await loadScheduledNotifications()
        } catch {
            print("Error scheduling daily summary: \(error)")
        }
    }
    
    func scheduleWeeklyReport(at day: Int, time: Date) async {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Report"
        content.body = "Time to review your weekly business report"
        content.sound = .default
        content.userInfo = ["type": "weekly_report"]
        
        var components = Calendar.current.dateComponents([.hour, .minute, .weekday], from: time)
        components.weekday = day // 1 = Sunday, 7 = Saturday
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weekly_report",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled weekly report on day \(day) at \(time)")
            await loadScheduledNotifications()
        } catch {
            print("Error scheduling weekly report: \(error)")
        }
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification actions
        switch response.actionIdentifier {
        case "VIEW_JOB":
            if let jobId = userInfo["jobId"] as? String {
                // Navigate to job detail
                NotificationCenter.default.post(
                    name: .navigateToJob,
                    object: nil,
                    userInfo: ["jobId": jobId]
                )
            }
            
        case "COMPLETE_JOB":
            if let jobId = userInfo["jobId"] as? String {
                // Mark job as complete
                NotificationCenter.default.post(
                    name: .completeJob,
                    object: nil,
                    userInfo: ["jobId": jobId]
                )
            }
            
        default:
            // Handle notification tap
            handleNotificationTap(userInfo: userInfo)
        }
        
        completionHandler()
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "job_reminder":
            if let jobId = userInfo["jobId"] as? String {
                NotificationCenter.default.post(
                    name: .navigateToJob,
                    object: nil,
                    userInfo: ["jobId": jobId]
                )
            }
            
        case "estimate_followup":
            if let estimateId = userInfo["estimateId"] as? String {
                NotificationCenter.default.post(
                    name: .navigateToEstimate,
                    object: nil,
                    userInfo: ["estimateId": estimateId]
                )
            }
            
        case "invoice_reminder":
            if let invoiceId = userInfo["invoiceId"] as? String {
                NotificationCenter.default.post(
                    name: .navigateToInvoice,
                    object: nil,
                    userInfo: ["invoiceId": invoiceId]
                )
            }
            
        case "equipment_maintenance":
            if let equipmentId = userInfo["equipmentId"] as? String {
                NotificationCenter.default.post(
                    name: .navigateToEquipment,
                    object: nil,
                    userInfo: ["equipmentId": equipmentId]
                )
            }
            
        case "lead_followup":
            if let leadId = userInfo["leadId"] as? String {
                NotificationCenter.default.post(
                    name: .navigateToLead,
                    object: nil,
                    userInfo: ["leadId": leadId]
                )
            }
            
        default:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToJob = Notification.Name("navigateToJob")
    static let navigateToEstimate = Notification.Name("navigateToEstimate")
    static let navigateToInvoice = Notification.Name("navigateToInvoice")
    static let navigateToEquipment = Notification.Name("navigateToEquipment")
    static let navigateToLead = Notification.Name("navigateToLead")
    static let completeJob = Notification.Name("completeJob")
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Authorization")) {
                    HStack {
                        Text("Notifications Enabled")
                        Spacer()
                        Toggle("", isOn: .constant(notificationManager.isAuthorized))
                            .disabled(true)
                    }
                    
                    if !notificationManager.isAuthorized {
                        Button("Enable Notifications") {
                            Task {
                                await notificationManager.requestAuthorization()
                            }
                        }
                        
                        Button("Open Settings") {
                            notificationManager.openSettings()
                        }
                    }
                }
                
                Section(header: Text("Scheduled Notifications")) {
                    if notificationManager.scheduledNotifications.isEmpty {
                        Text("No scheduled notifications")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(notificationManager.scheduledNotifications, id: \.identifier) { notification in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(notification.content.title)
                                    .font(.headline)
                                Text(notification.content.body)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let trigger = notification.trigger as? UNCalendarNotificationTrigger {
                                    Text("Next: \(trigger.nextTriggerDate() ?? Date.distantFuture, style: .relative)")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                Section(header: Text("Actions")) {
                    Button("Cancel All Notifications") {
                        Task {
                            await notificationManager.cancelAllNotifications()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}