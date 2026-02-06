import SwiftUI

struct JobBookingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var scheduler = SchedulingManager.shared
    
    let invoice: Invoice
    
    @State private var scheduledDate = Date()
    @State private var durationHours = 2.0
    @State private var notes = ""
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.slate900.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Job Info Summary
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("CLIENT")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.slate500)
                                        Text(invoice.clientName)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("INVOICE")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.slate500)
                                        Text(invoice.invoiceNumber)
                                            .font(.caption.bold())
                                            .foregroundColor(Theme.sky500)
                                    }
                                }
                                
                                Divider().background(Theme.slate700)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("ADDRESS")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Theme.slate500)
                                    Text(invoice.clientAddress)
                                        .font(.caption)
                                        .foregroundColor(Theme.slate300)
                                }
                            }
                            .padding()
                        }
                        
                        // Schedule Details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SCHEDULE DETAILS")
                                .font(Theme.labelFont)
                                .foregroundColor(Theme.slate500)
                            
                            GlassCard {
                                VStack(spacing: 20) {
                                    DatePicker("Service Date", selection: $scheduledDate)
                                        .accentColor(Theme.sky500)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Estimated Duration")
                                                .font(.caption)
                                                .foregroundColor(Theme.slate300)
                                            Spacer()
                                            Text("\(String(format: "%.1f", durationHours)) hours")
                                                .font(.caption.bold())
                                                .foregroundColor(Theme.sky500)
                                        }
                                        Slider(value: $durationHours, in: 0.5...8.0, step: 0.5)
                                            .accentColor(Theme.sky500)
                                    }
                                }
                                .padding()
                            }
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 16) {
                            Text("INTERNAL NOTES")
                                .font(Theme.labelFont)
                                .foregroundColor(Theme.slate500)
                            
                            GlassCard {
                                TextEditor(text: $notes)
                                    .frame(height: 100)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                                    .padding(4)
                            }
                        }
                        
                        Spacer(minLength: 40)
                        
                        NeonButton(title: "Confirm Booking", color: Theme.emerald500, icon: "calendar.badge.plus") {
                            saveBooking()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Book Job")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.slate400)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Booking Confirmed", isPresented: $showingConfirmation) {
            Button("Done") { dismiss() }
        } message: {
            Text("This job has been added to your schedule. You can now send an 'On My Way' notification.")
        }
    }
    
    private func saveBooking() {
        var job = ScheduledJob(
            invoiceID: invoice.id,
            clientName: invoice.clientName,
            clientAddress: invoice.clientAddress,
            scheduledDate: scheduledDate
        )
        job.durationHours = durationHours
        job.notes = notes
        
        scheduler.jobs.append(job)
        showingConfirmation = true
    }
}

#Preview {
    JobBookingView(invoice: Invoice(
        id: UUID(),
        estimateID: nil,
        clientName: "John Smith",
        clientEmail: "john@example.com",
        clientAddress: "123 Palm Ave, Destin, FL",
        date: Date(),
        status: .sent,
        items: [],
        total: 250.00,
        paymentLink: ""
    ))
}
