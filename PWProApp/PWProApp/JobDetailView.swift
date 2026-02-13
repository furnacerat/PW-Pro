import SwiftUI

struct JobDetailView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var scheduler = SchedulingManager.shared
    @StateObject var invoiceManager = InvoiceManager.shared
    
    @Binding var job: ScheduledJob
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Deployment Section
                JobDeploymentView(job: $job)
                
                // Status Section
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("STATUS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.slate500)
                            Text(job.status.rawValue)
                                .font(Theme.headingFont)
                                .foregroundColor(job.status.color)
                        }
                        Spacer()
                        Picker("Status", selection: $job.status) {
                            ForEach(ScheduledJob.JobStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(Theme.sky500)
                    }
                }
                
                // Client & Location Card
                GlassCard {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CLIENT")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.slate500)
                                Text(job.clientName)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            if let invID = job.invoiceID, let invoice = invoiceManager.getInvoice(id: invID) {
                                NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                                    HStack(spacing: 4) {
                                        Text(invoice.invoiceNumber)
                                        Image(systemName: "arrow.right.circle")
                                    }
                                    .font(.caption.bold())
                                    .foregroundColor(Theme.sky500)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LOCATION")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.slate500)
                            Text(job.clientAddress)
                                .font(Theme.bodyFont)
                                .foregroundColor(.white)
                            
                            Button {
                                openInMaps()
                            } label: {
                                HStack {
                                    Image(systemName: "map.fill")
                                    Text("Get Directions")
                                }
                                .font(.caption.bold())
                                .foregroundColor(Theme.sky500)
                            }
                        }
                    }
                    .padding()
                }
                
                // Job Details
                VStack(alignment: .leading, spacing: 16) {
                    Text("JOB DETAILS")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate500)
                    
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            DetailRow(icon: "calendar", label: "Date", value: job.scheduledDate.formatted(date: .long, time: .omitted))
                            DetailRow(icon: "clock", label: "Time", value: job.scheduledDate.formatted(date: .omitted, time: .shortened))
                            DetailRow(icon: "timer", label: "Expected Duration", value: "\(job.durationHours) hours")
                            
                            if !job.notes.isEmpty {
                                Divider().background(Theme.slate700)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("NOTES")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Theme.slate500)
                                    Text(job.notes)
                                        .font(.caption)
                                        .foregroundColor(Theme.slate300)
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                // Weather Intelligence:
                // We pass the job's date and surface type to the WeatherEngine.
                // It analyzes wind/rain conditions to recommend whether it's safe to work,
                // helping new technicians make safe decisions (e.g., "Too windy for ladder work").
                let weather = WeatherEngine.analyze(scheduledJob: job)
                VStack(alignment: .leading, spacing: 16) {
                    Text("WEATHER INSIGHT")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate500)
                    
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 20) {
                                WeatherMiniItem(icon: "wind", value: "\(Int(job.windSpeed)) MPH", label: "Wind")
                                WeatherMiniItem(icon: "cloud.rain.fill", value: "\(Int(job.rainChance))%", label: "Rain")
                                Spacer()
                                Text(job.surfaceType.rawValue)
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(6)
                                    .background(Theme.slate800)
                                    .foregroundColor(Theme.slate400)
                                    .cornerRadius(6)
                            }
                            
                            Divider().background(Theme.slate700)
                            
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: weather.status.icon)
                                    .foregroundColor(weather.status.color)
                                Text(weather.recommendation)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(weather.status.color.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding()
                    }
                }
                
                // Actions Section
                VStack(spacing: 12) {
                    // Arrive at Job button
                    if job.status == .scheduled || job.status == .inProgress {
                        let jobManager = ActiveJobManager.shared
                        let isThisJobActive = jobManager.activeJob?.id == job.id
                        
                        if isThisJobActive {
                            // Show active indicator
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Theme.emerald500)
                                    .frame(width: 8, height: 8)
                                Text("Job In Progress")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.emerald500)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.emerald500.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.emerald500.opacity(0.3), lineWidth: 1))
                        } else {
                            NeonButton(title: "Arrive at Job", color: Theme.emerald500, icon: "location.circle.fill") {
                                ActiveJobManager.shared.startJob(job)
                                // Post notification to switch to Field Tools tab
                                NotificationCenter.default.post(name: .switchToFieldTools, object: nil)
                                dismiss()
                            }
                        }
                    }
                    
                    NeonButton(title: "On My Way (SMS)", color: Theme.sky500, icon: "paperplane.fill") {
                        sendOnMyWaySMS()
                    }
                    
                    if job.status != .completed {
                        NeonButton(title: "Complete Job", color: Theme.emerald500, icon: "checkmark.circle.fill") {
                            job.status = .completed
                        }
                    } else if !BusinessSettings.shared.googleReviewLink.isEmpty {
                        NeonButton(title: job.reviewSent ? "Review Request Sent" : "Send Review Request", 
                                   color: job.reviewSent ? Theme.slate600 : Theme.amber500, 
                                   icon: job.reviewSent ? "checkmark.circle.fill" : "star.fill") {
                            sendReviewRequestSMS()
                            job.reviewSent = true
                        }
                        .disabled(job.reviewSent)
                    }
                    
                    Button {
                        showingDeleteConfirmation = true
                        HapticManager.warning()
                    } label: {
                        Text("Delete Job")
                            .font(.caption.bold())
                            .foregroundColor(Theme.red500)
                            .padding()
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 10)
            }
            .padding()
        }
        .background(Theme.slate900)
        .navigationTitle("Job Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        #if os(iOS)
        .alert("Delete Job?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                scheduler.deleteJob(job)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this job? This action cannot be undone.")
        }
        #endif
    }
    
    private func sendReviewRequestSMS() {
        ReputationManager.shared.requestReview(clientName: job.clientName, platform: .google)
    }
    
    private func sendOnMyWaySMS() {
        let businessName = BusinessSettings.shared.businessName
        let time = job.scheduledDate.formatted(date: .omitted, time: .shortened)
        let message = "Hi \(job.clientName), this is \(businessName). I'm on my way to your property for your pressure washing job scheduled for \(time). See you soon!"
        
        #if os(macOS)
        let picker = NSSharingServicePicker(items: [message])
        picker.show(relativeTo: .zero, of: NSApp.keyWindow?.contentView ?? NSView(), preferredEdge: .minY)
        #else
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            let activityVC = UIActivityViewController(activityItems: [message], applicationActivities: nil)
            rootViewController.present(activityVC, animated: true)
        }
        #endif
    }
    
    private func openInMaps() {
        let encodedAddress = job.clientAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString: String
        #if os(macOS)
        urlString = "http://maps.apple.com/?address=\(encodedAddress)"
        #else
        urlString = "maps://?address=\(encodedAddress)"
        #endif
        
        if let url = URL(string: urlString) {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #else
            UIApplication.shared.open(url)
            #endif
        }
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Theme.sky500)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Theme.slate500)
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            Spacer()
        }
    }
}
import SwiftUI

struct JobDeploymentView: View {
    @Binding var job: ScheduledJob
    @StateObject private var userManager = UserManager.shared
    @StateObject private var scheduler = SchedulingManager.shared
    
    @State private var showingUserPicker = false
    
    var currentUser: UserProfile? {
        guard let id = userManager.currentUserId else { return nil }
        return userManager.getUser(id: id)
    }
    
    var isCurrentUserDeployed: Bool {
        guard let id = userManager.currentUserId else { return false }
        return job.deployedUserIds.contains(id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DEPLOYMENT")
                .font(Theme.labelFont)
                .foregroundColor(Theme.slate500)
            
            GlassCard {
                VStack(spacing: 16) {
                    // 1. Current User Action
                    if let userId = userManager.currentUserId {
                        if isCurrentUserDeployed {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("You are deployed")
                                        .font(.headline)
                                        .foregroundColor(Theme.emerald500)
                                    Text("Complete the job or undeploy to switch.")
                                        .font(.caption)
                                        .foregroundColor(Theme.slate400)
                                }
                                Spacer()
                                Button {
                                    scheduler.undeployUser(userId, from: job)
                                } label: {
                                    Text("Undeploy")
                                        .font(.caption.bold())
                                        .foregroundColor(Theme.red500)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Theme.red500.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        } else {
                            Button {
                                scheduler.deployUser(userId, to: job)
                            } label: {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Deploy Myself")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.sky500)
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    Divider().background(Theme.slate700)
                    
                    // 2. Team List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Team on this job")
                                .font(.caption.bold())
                                .foregroundColor(Theme.slate400)
                            Spacer()
                            Button {
                                showingUserPicker = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Theme.sky500)
                            }
                        }
                        
                        if job.deployedUserIds.isEmpty {
                            Text("No one deployed yet")
                                .font(.caption)
                                .italic()
                                .foregroundColor(Theme.slate500)
                        } else {
                            ForEach(job.deployedUserIds, id: \.self) { userId in
                                HStack {
                                    Circle()
                                        .fill(Theme.slate700)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text(String(userManager.getName(for: userId).prefix(1)))
                                                .font(.caption.bold())
                                                .foregroundColor(.white)
                                        )
                                    
                                    Text(userManager.getName(for: userId))
                                        .font(.body)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    // Remove button (only if admin or valid permission, strictly simplistic for now)
                                    Button {
                                        scheduler.undeployUser(userId, from: job)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Theme.slate600)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingUserPicker) {
            UserPickerView(job: job)
                .presentationDetents([.medium])
        }
    }
}

struct UserPickerView: View {
    @Environment(\.dismiss) var dismiss
    let job: ScheduledJob
    @StateObject private var userManager = UserManager.shared
    @StateObject private var scheduler = SchedulingManager.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(userManager.users) { user in
                    if !job.deployedUserIds.contains(user.id) {
                        Button {
                            scheduler.deployUser(user.id, to: job)
                            dismiss()
                        } label: {
                            HStack {
                                Text(user.displayName)
                                    .foregroundColor(.white)
                                if let role = user.role {
                                    Spacer()
                                    Text(role)
                                        .font(.caption)
                                        .foregroundColor(Theme.slate400)
                                }
                            }
                        }
                        .listRowBackground(Theme.slate800)
                    }
                }
            }
            .background(Theme.slate900)
            .scrollContentBackground(.hidden)
            .navigationTitle("Deploy Team Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
