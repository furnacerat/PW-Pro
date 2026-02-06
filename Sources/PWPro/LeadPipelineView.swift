import SwiftUI

enum PipelineStage: String, CaseIterable {
    case new = "New Leads"
    case quoted = "Quote Sent"
    case scheduled = "Scheduled"
    
    var color: Color {
        switch self {
        case .new: return Theme.amber500
        case .quoted: return Theme.sky500
        case .scheduled: return Theme.emerald500
        }
    }
}

struct LeadPipelineView: View {
    @Binding var clients: [Client]
    
    // In a real app, these would be based on actual database fields.
    // here we simulate by filtering leads.
    var leads: [Client] {
        clients.filter { $0.status == .lead }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(PipelineStage.allCases, id: \.self) { stage in
                    PipelineColumn(stage: stage, leads: leadsForStage(stage))
                }
            }
            .padding()
        }
        .background(Theme.slate900)
        .navigationTitle("Lead Pipeline")
    }
    
    private func leadsForStage(_ stage: PipelineStage) -> [Client] {
        // Mocking stages based on tags for demo
        switch stage {
        case .new:
            return leads.filter { $0.tags.contains("New Quote") }
        case .quoted:
            return leads.filter { !$0.tags.contains("New Quote") && !$0.tags.contains("Scheduled") }
        case .scheduled:
            return leads.filter { $0.tags.contains("Scheduled") }
        }
    }
}

struct PipelineColumn: View {
    let stage: PipelineStage
    let leads: [Client]
    
    var body: some View {
        VStack(spacing: 16) {
            // Column Header
            HStack {
                Circle()
                    .fill(stage.color)
                    .frame(width: 8, height: 8)
                Text(stage.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.slate400)
                Spacer()
                Text("\(leads.count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.slate500)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.slate800)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 4)
            
            // Cards
            VStack(spacing: 12) {
                if leads.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundColor(Theme.slate700)
                        Text("No leads")
                            .font(.caption)
                            .foregroundColor(Theme.slate600)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Theme.slate800.opacity(0.3))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .foregroundColor(Theme.slate700)
                    )
                } else {
                    ForEach(leads) { lead in
                        PipelineCard(lead: lead)
                    }
                }
            }
            
            Spacer()
        }
        .frame(width: 280)
    }
}

struct PipelineCard: View {
    let lead: Client
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(lead.name)
                    .font(Theme.bodyFont)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(lead.address)
                    .font(.caption2)
                    .foregroundColor(Theme.slate400)
                    .lineLimit(1)
                
                HStack {
                    if let lastAct = lead.lastInteraction {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 8))
                            Text(lastAct.formatted(.relative(presentation: .numeric)))
                                .font(.system(size: 8))
                        }
                        .foregroundColor(Theme.slate500)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        ForEach(lead.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 8, weight: .medium))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Theme.slate800)
                                .foregroundColor(Theme.slate300)
                                .cornerRadius(2)
                        }
                    }
                }
            }
        }
    }
}
