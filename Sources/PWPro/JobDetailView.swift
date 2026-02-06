import SwiftUI

struct JobDetailView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var scheduler = SchedulingManager.shared
    @StateObject var invoiceManager = InvoiceManager.shared
    
    @Binding var job: ScheduledJob
    
    @State private var showingShareSheet = false
    @State private var shareContent: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
                
                // Weather Insight
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
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [shareContent])
        }
        #endif
    }
    
    private func sendReviewRequestSMS() {
        let businessName = BusinessSettings.shared.businessName
        let link = BusinessSettings.shared.googleReviewLink
        let message = "Hi \(job.clientName), thank you for choosing \(businessName)! We'd love to hear about your experience. Could you leave us a quick review here? \(link)"
        
        #if os(macOS)
        let picker = NSSharingServicePicker(items: [message])
        picker.show(relativeTo: .zero, of: NSApp.keyWindow?.contentView ?? NSView(), preferredEdge: .minY)
        #else
        shareContent = message
        showingShareSheet = true
        #endif
    }
    
    private func sendOnMyWaySMS() {
        let businessName = BusinessSettings.shared.businessName
        let time = job.scheduledDate.formatted(date: .omitted, time: .shortened)
        let message = "Hi \(job.clientName), this is \(businessName). I'm on my way to your property for your pressure washing job scheduled for \(time). See you soon!"
        
        #if os(macOS)
        let picker = NSSharingServicePicker(items: [message])
        picker.show(relativeTo: .zero, of: NSApp.keyWindow?.contentView ?? NSView(), preferredEdge: .minY)
        #else
        shareContent = message
        showingShareSheet = true
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
