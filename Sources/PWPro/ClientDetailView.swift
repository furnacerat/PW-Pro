import SwiftUI

struct ClientDetailView: View {
    @Binding var client: Client
    @State private var showingAddNote = false
    @State private var newNote = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Profile
                GlassCard {
                    VStack(spacing: 16) {
                        HStack(spacing: 20) {
                            Text(String(client.name.prefix(1)))
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(client.status.color.opacity(0.3))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(client.status.color.opacity(0.5), lineWidth: 2))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(client.name)
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Text(client.status.rawValue)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(client.status.color.opacity(0.2))
                                        .foregroundColor(client.status.color)
                                        .cornerRadius(8)
                                    
                                    ForEach(client.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.system(size: 10, weight: .medium))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Theme.slate800)
                                            .foregroundColor(Theme.slate400)
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            Spacer()
                        }
                        
                        Divider().background(Theme.slate700)
                        
                        // Contact Actions
                        HStack(spacing: 12) {
                            ContactAction(icon: "phone.fill", title: "Call", color: Theme.sky500) {
                                // Simulate call
                            }
                            ContactAction(icon: "envelope.fill", title: "Email", color: Theme.sky500) {
                                // Simulate email
                            }
                            ContactAction(icon: "map.fill", title: "Directions", color: Theme.sky500) {
                                // Simulate navigation
                            }
                        }
                    }
                    .padding()
                }
                
                // Stats Grid
                HStack(spacing: 16) {
                    DetailStatCard(title: "LIFETIME VALUE", value: "$\(Int(client.totalLifetimeValue))", icon: "dollarsign.circle")
                    DetailStatCard(title: "TOTAL JOBS", value: "\(client.jobHistory.count)", icon: "briefcase")
                }
                
                // Job History
                VStack(alignment: .leading, spacing: 16) {
                    Text("JOB HISTORY")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                    
                    if client.jobHistory.isEmpty {
                        Text("No jobs recorded yet.")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.slate500)
                            .padding()
                    } else {
                        ForEach(client.jobHistory.sorted(by: { $0.date > $1.date })) { job in
                            JobHistoryRow(job: job)
                        }
                    }
                }
                
                // Interaction Log
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("INTERACTION LOG")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate400)
                        Spacer()
                        Button {
                            showingAddNote.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                Text("New Note")
                            }
                            .font(.caption.bold())
                            .foregroundColor(Theme.sky500)
                        }
                    }
                    
                    ForEach(client.interactions.sorted(by: { $0.date > $1.date })) { interaction in
                        InteractionRow(interaction: interaction)
                    }
                }
            }
            .padding()
        }
        .background(Theme.slate900)
        .navigationTitle("Client Details")
        .sheet(isPresented: $showingAddNote) {
            AddNoteView(client: $client)
        }
    }
}

struct ContactAction: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.headline)
                Text(title)
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct DetailStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(Theme.sky500)
                    Spacer()
                }
                Text(value)
                    .font(Theme.headingFont)
                    .foregroundColor(.white)
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.slate500)
            }
        }
    }
}

struct JobHistoryRow: View {
    let job: JobRecord
    
    var body: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.serviceType)
                        .font(Theme.bodyFont)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(job.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(Theme.slate400)
                }
                Spacer()
                Text("$\(Int(job.amount))")
                    .font(Theme.labelFont)
                    .foregroundColor(Theme.emerald500)
            }
        }
    }
}

struct InteractionRow: View {
    let interaction: InteractionLog
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Theme.slate700)
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: iconForType(interaction.type))
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(interaction.type.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(Theme.slate300)
                    Spacer()
                    Text(interaction.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 10))
                        .foregroundColor(Theme.slate500)
                }
                Text(interaction.notes)
                    .font(.caption)
                    .foregroundColor(Theme.slate400)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, 8)
    }
    
    func iconForType(_ type: InteractionType) -> String {
        switch type {
        case .call: return "phone.fill"
        case .email: return "envelope.fill"
        case .onsite: return "map.fill"
        case .note: return "pencil"
        }
    }
}

struct AddNoteView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var client: Client
    @State private var notes = ""
    @State private var type: InteractionType = .note
    @State private var isSuggesting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $type) {
                    ForEach([InteractionType.note, .call, .email, .onsite], id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                
                Section("Notes") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextEditor(text: $notes)
                            .frame(height: 150)
                        
                        Button {
                            generateAISuggestion()
                        } label: {
                            HStack {
                                if isSuggesting {
                                    ProgressView().tint(Theme.sky500).scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text("AI Suggest Response")
                            }
                            .font(.caption.bold())
                            .foregroundColor(Theme.sky500)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Theme.sky500.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .disabled(isSuggesting)
                    }
                }
            }
            .navigationTitle("New Interaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let log = InteractionLog(date: Date(), type: type, notes: notes)
                        client.interactions.append(log)
                        dismiss()
                    }
                    .disabled(notes.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func generateAISuggestion() {
        isSuggesting = true
        // Simulate AI generation based on client history
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let suggestions: [InteractionType: String] = [
                .note: "Followed up on the quote for the driveway cleaning. Client mentioned they are waiting on a tax refund to proceed.",
                .call: "Spoke with client regarding the \(client.serviceFrequencyMonths ?? 12)-month service interval. They appreciated the reminder and scheduled for next week.",
                .email: "Sent professional follow-up regarding the referral program. Reminded them of their code: \(client.referralCode).",
                .onsite: "Walked the property with the homeowner. Noted heavy lichen on the north-side roof. Recommended soft wash treatment."
            ]
            
            withAnimation {
                notes = suggestions[type] ?? ""
                isSuggesting = false
            }
        }
    }
}
