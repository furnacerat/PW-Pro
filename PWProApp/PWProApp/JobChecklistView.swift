import SwiftUI

// MARK: - Checklist Category

enum ChecklistCategory: String, CaseIterable, Identifiable {
    case safety = "Safety & PPE"
    case equipment = "Equipment Check"
    case chemicals = "Chemical Prep"
    case site = "Site Assessment"
    case customer = "Customer Relations"
    case operational = "Wash Execution"
    case cleanup = "Post-Job Wrap-Up"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .safety: return "shield.checkered"
        case .equipment: return "wrench.and.screwdriver"
        case .chemicals: return "flask.fill"
        case .site: return "eye.fill"
        case .customer: return "person.2.fill"
        case .operational: return "water.waves"
        case .cleanup: return "sparkles"
        }
    }
    
    var color: Color {
        switch self {
        case .safety: return Theme.red500
        case .equipment: return Theme.sky500
        case .chemicals: return Theme.emerald500
        case .site: return Theme.amber500
        case .customer: return Theme.purple500
        case .operational: return Color.cyan
        case .cleanup: return Theme.pink500
        }
    }
}

// MARK: - Checklist Item

struct ChecklistItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let category: ChecklistCategory
    var isCompleted: Bool = false
    
    init(_ title: String, subtitle: String? = nil, category: ChecklistCategory) {
        self.title = title
        self.subtitle = subtitle
        self.category = category
    }
}

// MARK: - Job Checklist View

struct JobChecklistView: View {
    @State private var items: [ChecklistItem] = Self.defaultItems
    @State private var showResetConfirmation = false
    @State private var expandedCategories: Set<String> = Set(ChecklistCategory.allCases.map(\.rawValue))
    
    private var completedCount: Int {
        items.filter(\.isCompleted).count
    }
    
    private var totalCount: Int {
        items.count
    }
    
    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress Header
                progressHeader
                
                // Category Sections
                ForEach(ChecklistCategory.allCases) { category in
                    let categoryItems = items.filter { $0.category == category }
                    if !categoryItems.isEmpty {
                        categorySection(category: category, items: categoryItems)
                    }
                }
                
                // Reset Button
                resetButton
                    .padding(.top, 8)
                    .padding(.bottom, 40)
            }
            .padding(.top)
        }
        .background(Theme.slate900)
        .confirmationDialog("Reset Checklist?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Reset All Items", role: .destructive) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    for i in items.indices {
                        items[i].isCompleted = false
                    }
                }
                HapticManager.notification(.warning)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will uncheck all items and start fresh.")
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("JOB READINESS")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate400)
                        
                        Text("\(completedCount) of \(totalCount) complete")
                            .font(Theme.bodyFont)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Circular Progress
                    ZStack {
                        Circle()
                            .stroke(Theme.slate700, lineWidth: 6)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                progressColor,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.5), value: progress)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(progressColor)
                    }
                }
                
                // Linear Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.slate700)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [progressColor.opacity(0.8), progressColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 8)
                            .animation(.spring(response: 0.5), value: progress)
                    }
                }
                .frame(height: 8)
                
                if completedCount == totalCount && totalCount > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(Theme.emerald500)
                        Text("All clear — you're ready to roll!")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.emerald500)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var progressColor: Color {
        if progress >= 1.0 { return Theme.emerald500 }
        if progress >= 0.6 { return Theme.amber500 }
        return Theme.sky500
    }
    
    // MARK: - Category Section
    
    private func categorySection(category: ChecklistCategory, items: [ChecklistItem]) -> some View {
        let isExpanded = expandedCategories.contains(category.rawValue)
        let completedInCategory = items.filter(\.isCompleted).count
        
        return VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isExpanded {
                        expandedCategories.remove(category.rawValue)
                    } else {
                        expandedCategories.insert(category.rawValue)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.system(size: 18))
                        .foregroundColor(category.color)
                        .frame(width: 32)
                    
                    Text(category.rawValue)
                        .font(Theme.industrialSubheading)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Count badge
                    Text("\(completedInCategory)/\(items.count)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(completedInCategory == items.count ? Theme.emerald500 : Theme.slate400)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            completedInCategory == items.count
                            ? Theme.emerald500.opacity(0.15)
                            : Theme.slate800
                        )
                        .cornerRadius(6)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.slate500)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            
            // Items
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        checklistRow(item: item)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.slate800.opacity(0.3))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Checklist Row
    
    private func checklistRow(item: ChecklistItem) -> some View {
        Button {
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    items[idx].isCompleted.toggle()
                }
                HapticManager.selection()
            }
        } label: {
            HStack(spacing: 14) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(item.isCompleted ? Color.clear : Theme.slate600, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    
                    if item.isCompleted {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Theme.emerald500)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .animation(.spring(response: 0.25), value: item.isCompleted)
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(Theme.bodyFont)
                        .foregroundColor(item.isCompleted ? Theme.slate500 : .white)
                        .strikethrough(item.isCompleted, color: Theme.slate600)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(Theme.slate500)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Reset Button
    
    private var resetButton: some View {
        Button {
            showResetConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                Text("Reset Checklist")
            }
            .font(Theme.labelFont)
            .foregroundColor(Theme.slate400)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Theme.slate800.opacity(0.5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.slate700, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Default Pre-Job Checklist Items
    
    static let defaultItems: [ChecklistItem] = [
        // Safety & PPE
        ChecklistItem("Safety glasses / goggles on", subtitle: "Chemical-rated splash protection", category: .safety),
        ChecklistItem("Chemical-resistant gloves", subtitle: "Nitrile or rubber — no fabric", category: .safety),
        ChecklistItem("Non-slip boots / steel-toe footwear", category: .safety),
        ChecklistItem("Hearing protection available", subtitle: "Required for extended high-PSI work", category: .safety),
        ChecklistItem("First aid kit stocked & accessible", category: .safety),
        ChecklistItem("SDS sheets on hand for chemicals", subtitle: "Keep digital copies on phone as backup", category: .safety),
        ChecklistItem("Secure children & pets indoors", subtitle: "Confirm with homeowner before starting", category: .safety),
        ChecklistItem("Place warning signs / cones", subtitle: "Mark work area for passersby", category: .safety),
        
        // Equipment Check
        ChecklistItem("Check engine oil & pump oil levels", category: .equipment),
        ChecklistItem("Verify fuel level", subtitle: "Enough for the full job + buffer", category: .equipment),
        ChecklistItem("Inspect air filter", subtitle: "Replace if visibly dirty", category: .equipment),
        ChecklistItem("Inspect hoses for cracks or leaks", subtitle: "Check fittings, couplers, and O-rings", category: .equipment),
        ChecklistItem("Verify nozzle tips are correct", subtitle: "Match tip to surface — 0° 15° 25° 40° 65°", category: .equipment),
        ChecklistItem("Check unloader valve operation", category: .equipment),
        ChecklistItem("Test trigger gun safety latch", category: .equipment),
        ChecklistItem("Test surface cleaner spin", subtitle: "Ensure bar spins freely, no clogs", category: .equipment),
        ChecklistItem("Downstream injector working", subtitle: "Test suction with water before chemicals", category: .equipment),
        ChecklistItem("Check pump pressure / flow", subtitle: "Verify PSI at tip matches expectations", category: .equipment),
        
        // Chemical Prep
        ChecklistItem("Mix SH to correct ratio", subtitle: "Use the Calculator tab for exact amounts", category: .chemicals),
        ChecklistItem("Surfactant added to mix", subtitle: "Improves dwell time and coverage", category: .chemicals),
        ChecklistItem("Pre-treat / degreaser ready if needed", category: .chemicals),
        ChecklistItem("Rinse water source confirmed", subtitle: "Adequate water flow — min 5 GPM", category: .chemicals),
        ChecklistItem("Connect to spigot & bleed air from lines", subtitle: "Run water through before pressurizing", category: .chemicals),
        ChecklistItem("Chemical containers sealed & labeled", subtitle: "DOT-compliant if transporting", category: .chemicals),
        
        // Site Assessment
        ChecklistItem("Walk the property perimeter", subtitle: "Note obstacles, fragile items, damage", category: .site),
        ChecklistItem("Note & photograph existing damage", subtitle: "Take photos before starting — CYA", category: .site),
        ChecklistItem("Cover / move delicate plants", subtitle: "Pre-wet vegetation before applying SH", category: .site),
        ChecklistItem("Move furniture, mats, & décor 15+ ft away", subtitle: "Clear the entire work zone", category: .site),
        ChecklistItem("Close all windows and doors", subtitle: "Prevent water intrusion", category: .site),
        ChecklistItem("Move vehicles out of overspray zone", category: .site),
        ChecklistItem("Cover electrical outlets & panels", subtitle: "Tape or plastic wrap — GFCI required", category: .site),
        ChecklistItem("Cover / protect cameras & light fixtures", category: .site),
        ChecklistItem("Check weather conditions", subtitle: "Avoid high wind, rain, or freezing temps", category: .site),
        
        // Customer Relations
        ChecklistItem("Confirm job scope with customer", subtitle: "Review what's being cleaned and what's not", category: .customer),
        ChecklistItem("Set expectations on results", subtitle: "Disclose limitations (old stains, oxidation)", category: .customer),
        ChecklistItem("Collect deposit or confirm payment method", category: .customer),
        ChecklistItem("Take 'before' photos", subtitle: "Use the Before/After tab for side-by-side", category: .customer),
        ChecklistItem("Advise customer of timeline", subtitle: "Estimated start-to-finish duration", category: .customer),
        
        // Wash Execution
        ChecklistItem("Test spot on inconspicuous area", subtitle: "Start with lowest pressure / widest angle", category: .operational),
        ChecklistItem("Apply detergent from bottom up", subtitle: "Prevents streaking on vertical surfaces", category: .operational),
        ChecklistItem("Allow proper dwell time", subtitle: "Let chemicals work 5-10 min before rinsing", category: .operational),
        ChecklistItem("Maintain 6–12 inch nozzle distance", subtitle: "Use consistent overlapping strokes", category: .operational),
        ChecklistItem("Rinse from top down", subtitle: "Ensure all soap and debris is fully removed", category: .operational),
        ChecklistItem("Adjust pressure for surface type", subtitle: "Soft wash siding, high pressure concrete", category: .operational),
        
        // Post-Job Wrap-Up
        ChecklistItem("Rinse all treated surfaces thoroughly", category: .cleanup),
        ChecklistItem("Water down all plants & landscaping", subtitle: "Neutralize any chemical runoff", category: .cleanup),
        ChecklistItem("Remove tape, plastic & outlet covers", subtitle: "Restore all protected fixtures", category: .cleanup),
        ChecklistItem("Flush equipment lines with clean water", category: .cleanup),
        ChecklistItem("Collect and stow all hoses & gear", category: .cleanup),
        ChecklistItem("Take 'after' photos", subtitle: "Upload in the Before/After tab", category: .cleanup),
        ChecklistItem("Walk final results with customer", subtitle: "Ensure satisfaction before leaving", category: .cleanup),
        ChecklistItem("Collect final payment / send invoice", subtitle: "Use the Invoicing tab", category: .cleanup),
        ChecklistItem("Request review or referral", subtitle: "Best time to ask is right after a great job", category: .cleanup),
        ChecklistItem("Drain chemical tanks if done for the day", subtitle: "Don't leave SH sitting overnight", category: .cleanup),
    ]
}

#Preview {
    JobChecklistView()
}
