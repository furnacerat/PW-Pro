import SwiftUI

// MARK: - Field Tools Tab Definition

enum FieldToolTab: Int, CaseIterable {
    case calculator = 0
    case chemicals = 1
    case checklist = 2
    case damageDocs = 3
    case arMeasure = 4
    case beforeAfter = 5
    
    var title: String {
        switch self {
        case .calculator: return "Calculator"
        case .chemicals: return "Chemicals"
        case .checklist: return "Checklist"
        case .damageDocs: return "Damage Docs"
        case .arMeasure: return "AR Measure"
        case .beforeAfter: return "Before/After"
        }
    }
    
    var icon: String {
        switch self {
        case .calculator: return "function"
        case .chemicals: return "flask.fill"
        case .checklist: return "checklist"
        case .damageDocs: return "exclamationmark.shield.fill"
        case .arMeasure: return "camera.viewfinder"
        case .beforeAfter: return "photo.on.rectangle.angled"
        }
    }
}

struct FieldToolsView: View {
    @State private var selectedTab: FieldToolTab
    @StateObject private var jobManager = ActiveJobManager.shared
    @StateObject private var scheduler = SchedulingManager.shared
    @State private var showStartJobSheet = false
    @State private var showCompleteJobSheet = false
    @State private var completedPackage: JobPackage?
    @State private var elapsedTimer: Timer?
    @State private var elapsedDisplay = "0:00"
    
    init(selectedTab: Int = 0) {
        _selectedTab = State(initialValue: FieldToolTab(rawValue: selectedTab) ?? .calculator)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.slate900.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Active Job Banner or Start Job Prompt
                    if jobManager.isActive {
                        activeJobBanner
                    } else {
                        startJobPrompt
                    }
                    
                    // Premium scrollable tab bar
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(FieldToolTab.allCases, id: \.rawValue) { tab in
                                    FieldToolTabButton(
                                        tab: tab,
                                        isSelected: selectedTab == tab
                                    ) {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            selectedTab = tab
                                        }
                                        HapticManager.selection()
                                    }
                                    .id(tab.rawValue)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(
                            Theme.slate800.opacity(0.6)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 0.5)
                                        .foregroundColor(Theme.slate700.opacity(0.5)),
                                    alignment: .bottom
                                )
                        )
                        .onChange(of: selectedTab) { _, newTab in
                            withAnimation {
                                proxy.scrollTo(newTab.rawValue, anchor: .center)
                            }
                        }
                    }
                    
                    // Content
                    switch selectedTab {
                    case .calculator:
                        MixingCalculatorView()
                    case .chemicals:
                        ChemicalsView()
                    case .checklist:
                        JobChecklistView()
                    case .damageDocs:
                        DamageDocumentationView()
                    case .arMeasure:
                        SmartCameraView(estimatedSqFt: $dummyArea, identifiedSurface: $dummySurface)
                    case .beforeAfter:
                        ShowcaseView()
                    }
                }
                
                // Floating Complete Job Button
                if jobManager.isActive {
                    VStack {
                        Spacer()
                        Button(action: { showCompleteJobSheet = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Complete Job")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Theme.emerald500, Theme.emerald500.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Theme.emerald500.opacity(0.4), radius: 16, y: 6)
                            )
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Field Tools")
            .sheet(isPresented: $showStartJobSheet) {
                StartJobSheet(scheduler: scheduler, jobManager: jobManager)
            }
            .sheet(isPresented: $showCompleteJobSheet) {
                CompleteJobSheet(jobManager: jobManager, completedPackage: $completedPackage)
            }
            .onAppear { startTimer() }
            .onDisappear { stopTimer() }
            .alert("Job Complete!", isPresented: $jobManager.showReviewPrompt) {
                Button("Send Review Request") {
                    if let package = completedPackage {
                        ReputationManager.shared.requestReview(clientName: package.clientName, platform: .google)
                    }
                }
                Button("Later", role: .cancel) { }
            } message: {
                Text("Would you like to send a review request to the client now?")
            }
        }
    }
    
    // MARK: - Active Job Banner
    
    private var activeJobBanner: some View {
        HStack(spacing: 12) {
            // Pulsing indicator
            Circle()
                .fill(Theme.emerald500)
                .frame(width: 10, height: 10)
                .shadow(color: Theme.emerald500, radius: 4)
                .overlay(
                    Circle()
                        .stroke(Theme.emerald500.opacity(0.3), lineWidth: 2)
                        .scaleEffect(1.5)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(jobManager.jobDisplayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(jobManager.jobDisplayAddress)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.slate400)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Live timer
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 11))
                Text(elapsedDisplay)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
            }
            .foregroundColor(Theme.emerald500)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.emerald500.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Theme.slate800.opacity(0.8)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(Theme.emerald500.opacity(0.3)),
                    alignment: .bottom
                )
        )
    }
    
    // MARK: - Start Job Prompt
    
    private var startJobPrompt: some View {
        Button(action: { showStartJobSheet = true }) {
            HStack(spacing: 10) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.sky500)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Arrive at Job")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    let todayJobs = scheduler.jobs(for: Date()).filter { $0.status == .scheduled }
                    Text(todayJobs.isEmpty ? "Start a job to link all tools" : "\(todayJobs.count) job\(todayJobs.count == 1 ? "" : "s") scheduled today")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.slate400)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.slate500)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Theme.slate800.opacity(0.6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Theme.sky500.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                elapsedDisplay = jobManager.formattedElapsedTime
            }
        }
    }
    
    private func stopTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }
    
    // Temporary state for the camera tool when used in standalone mode
    @State private var dummyArea: Double = 0
    @State private var dummySurface: SurfaceType = .sidingVinyl
}

// MARK: - Start Job Sheet

struct StartJobSheet: View {
    @ObservedObject var scheduler: SchedulingManager
    @ObservedObject var jobManager: ActiveJobManager
    @Environment(\.dismiss) private var dismiss
    
    var todayJobs: [ScheduledJob] {
        scheduler.jobs(for: Date()).filter { $0.status == .scheduled }
    }
    
    var upcomingJobs: [ScheduledJob] {
        scheduler.jobs.filter {
            $0.status == .scheduled && !Calendar.current.isDateInToday($0.scheduledDate)
        }.sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.slate900.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Theme.sky500.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "location.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(Theme.sky500)
                            }
                            Text("Select a Job to Start")
                                .font(Theme.headingFont)
                                .foregroundColor(.white)
                            Text("All field tools will auto-link to this job")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.slate400)
                        }
                        .padding(.top, 8)
                        
                        // Today's Jobs
                        if !todayJobs.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(Theme.emerald500)
                                    Text("TODAY'S JOBS")
                                        .font(Theme.labelFont)
                                        .foregroundColor(Theme.slate400)
                                }
                                .padding(.horizontal, 16)
                                
                                ForEach(todayJobs) { job in
                                    StartJobCard(job: job) {
                                        jobManager.startJob(job)
                                        dismiss()
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        
                        // Upcoming Jobs
                        if !upcomingJobs.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock")
                                        .foregroundColor(Theme.amber500)
                                    Text("UPCOMING")
                                        .font(Theme.labelFont)
                                        .foregroundColor(Theme.slate400)
                                }
                                .padding(.horizontal, 16)
                                
                                ForEach(upcomingJobs.prefix(5)) { job in
                                    StartJobCard(job: job) {
                                        jobManager.startJob(job)
                                        dismiss()
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                        
                        // Empty state
                        if todayJobs.isEmpty && upcomingJobs.isEmpty {
                            GlassCard {
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 36))
                                        .foregroundColor(Theme.slate500)
                                    Text("No Scheduled Jobs")
                                        .font(Theme.bodyFont)
                                        .foregroundColor(Theme.slate400)
                                    Text("Schedule jobs from the Calendar tab first, or create an estimate/invoice.")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.slate500)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Arrive at Job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.slate400)
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Start Job Card

struct StartJobCard: View {
    let job: ScheduledJob
    let onStart: () -> Void
    
    var body: some View {
        Button(action: onStart) {
            HStack(spacing: 14) {
                // Status dot
                Circle()
                    .fill(job.status.color)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.clientName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(job.clientAddress)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.slate400)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text(job.scheduledDate, format: .dateTime.hour().minute())
                                .font(.system(size: 11, design: .monospaced))
                        }
                        .foregroundColor(Theme.slate500)
                        
                        HStack(spacing: 3) {
                            Image(systemName: "timer")
                                .font(.system(size: 9))
                            Text("\(String(format: "%.1f", job.durationHours))h est.")
                                .font(.system(size: 11, design: .monospaced))
                        }
                        .foregroundColor(Theme.slate500)
                    }
                }
                
                Spacer()
                
                // Start button
                Text("START")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.emerald500)
                    .cornerRadius(8)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.slate800.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Theme.slate700.opacity(0.5), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Complete Job Sheet

struct CompleteJobSheet: View {
    @ObservedObject var jobManager: ActiveJobManager
    @Binding var completedPackage: JobPackage?
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirm = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.slate900.ignoresSafeArea()
                
                if let package = completedPackage {
                    // Completed Summary
                    completedSummary(package)
                } else {
                    // Pre-complete review
                    preCompleteReview
                }
            }
            .navigationTitle(completedPackage != nil ? "Job Complete!" : "Complete Job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(completedPackage != nil ? "Done" : "Cancel") {
                        completedPackage = nil
                        dismiss()
                    }
                    .foregroundColor(Theme.slate400)
                }
            }
        }
        .presentationDetents([.large])
    }
    
    // MARK: - Pre-Complete Review
    
    private var preCompleteReview: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.emerald500.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Theme.emerald500)
                    }
                    Text("Ready to Complete?")
                        .font(Theme.headingFont)
                        .foregroundColor(.white)
                    Text("This will package all data and close the job")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.slate400)
                }
                .padding(.top, 8)
                
                // Job Summary
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("JOB SUMMARY")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate400)
                        
                        summaryRow(icon: "person.fill", label: "Client", value: jobManager.jobDisplayName)
                        summaryRow(icon: "mappin", label: "Location", value: jobManager.jobDisplayAddress)
                        summaryRow(icon: "timer", label: "Duration", value: jobManager.formattedElapsedTime)
                    }
                }
                .padding(.horizontal, 16)
                
                // Collected Data
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("COLLECTED DATA")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate400)
                        
                        let checkDone = jobManager.checklistState.filter { $0.value }.count
                        let checkTotal = jobManager.checklistState.count
                        summaryRow(icon: "checklist", label: "Checklist",
                                   value: checkTotal > 0 ? "\(checkDone)/\(checkTotal) items" : "Not started")
                        
                        summaryRow(icon: "exclamationmark.shield.fill", label: "Damage Reports",
                                   value: "\(jobManager.damageRecords.count) report\(jobManager.damageRecords.count == 1 ? "" : "s")")
                        
                        summaryRow(icon: "photo.on.rectangle.angled", label: "Before/After",
                                   value: jobManager.beforeImage != nil || jobManager.afterImage != nil ? "Captured" : "Not taken")
                    }
                }
                .padding(.horizontal, 16)
                
                // Session Notes
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SESSION NOTES (OPTIONAL)")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate400)
                        
                        TextEditor(text: $jobManager.sessionNotes)
                            .font(Theme.bodyFont)
                            .foregroundColor(.white)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 60)
                            .padding(8)
                            .background(Theme.slate800)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                
                // Complete Button
                Button {
                    completedPackage = jobManager.completeJob()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Complete & Package Job")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Theme.emerald500, Theme.emerald500.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: Theme.emerald500.opacity(0.3), radius: 12, y: 4)
                }
                .padding(.horizontal, 16)
                
                // Cancel session option
                Button {
                    jobManager.cancelSession()
                    dismiss()
                } label: {
                    Text("Cancel Job Session")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.red500)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Completed Summary
    
    private func completedSummary(_ package: JobPackage) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Success hero
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.emerald500.opacity(0.15))
                            .frame(width: 100, height: 100)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.emerald500)
                    }
                    Text("Job Completed!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text(package.formattedDate)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.slate400)
                }
                .padding(.top, 8)
                
                // Package details
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("JOB RECORD")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate400)
                        
                        summaryRow(icon: "person.fill", label: "Client", value: package.clientName)
                        summaryRow(icon: "mappin", label: "Location", value: package.clientAddress)
                        summaryRow(icon: "clock", label: "Started", value: package.formattedStartTime)
                        summaryRow(icon: "clock.badge.checkmark", label: "Completed", value: package.formattedCompletedTime)
                        summaryRow(icon: "timer", label: "Duration", value: package.formattedDuration)
                        summaryRow(icon: "checklist", label: "Checklist", value: "\(package.checklistCompleted.count)/\(package.checklistTotal)")
                        summaryRow(icon: "camera.fill", label: "Damage Photos", value: "\(package.damagePhotoFileNames.count)")
                    }
                }
                .padding(.horizontal, 16)
                
                // Done button
                Button {
                    completedPackage = nil
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.sky500)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Theme.sky500)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Theme.slate400)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }
}

// MARK: - Premium Tab Button

struct FieldToolTabButton: View {
    let tab: FieldToolTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13, weight: .semibold))
                
                Text(tab.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.sky500.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.sky500.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.slate800.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.slate700.opacity(0.5), lineWidth: 0.5)
                            )
                    }
                }
            )
            .foregroundColor(isSelected ? Theme.sky500 : Theme.slate400)
            .scaleEffect(isSelected ? 1.0 : 0.97)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// Legacy TabButton kept for any other usage
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.labelFont)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Theme.sky500.opacity(0.2) : Color.clear)
                .foregroundColor(isSelected ? Theme.sky500 : Theme.slate400)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(isSelected ? Theme.sky500 : Color.clear),
                    alignment: .bottom
                )
        }
        .buttonStyle(.plain)
    }
}

enum MixingMode: String, CaseIterable {
    case batch = "Batch Mix"
    case downstream = "Downstream"
    case manifold = "Manifold"
}

struct MixingCalculatorView: View {
    // Filter out chemicals that don't have a mixing strategy
    var mixableChemicals: [Chemical] {
        ChemicalData.allChemicals.filter { $0.mixingStrategy != nil }
    }
    
    @State private var selectedChemical: Chemical?
    @State private var mixingMode: MixingMode = .batch
    
    // Inputs
    @State private var tankSize: Double = 50 // Gallons
    @State private var injectorRatio: Double = 10 // 10:1
    
    // Variable Inputs (depending on strategy)
    @State private var targetPercentage: Double = 1.5 // % (SH)
    @State private var sourceSH: Double = 12.5 // % (Generic SH)
    @State private var dilutionRatio: Double = 4.0 // X:1 (Degreasers)
    @State private var ozPerGallon: Double = 1.0 // oz/gal (Surfactants)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Mode Selection
                Picker("Mode", selection: $mixingMode) {
                    ForEach(MixingMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Chemical Selector
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CHEMICAL AGENT")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate400)
                        
                        Menu {
                            ForEach(mixableChemicals) { chem in
                                Button(action: { 
                                    selectedChemical = chem
                                    updateDefaults(for: chem)
                                }) {
                                    HStack {
                                        Text(chem.name)
                                        if chem.isBrandName { Spacer(); Text("Brand") }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedChemical?.name ?? "Select Chemical")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundColor(Theme.sky500)
                            }
                            .padding()
                            .background(Theme.slate800)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.slate700, lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal)
                .onAppear {
                    if selectedChemical == nil, let first = mixableChemicals.first {
                        selectedChemical = first
                        updateDefaults(for: first)
                    }
                }
                
                // Dynamic Inputs
                if let chemical = selectedChemical, let strategy = chemical.mixingStrategy {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("SETTINGS")
                                .font(Theme.labelFont)
                                .foregroundColor(Theme.slate400)
                            
                            // 1. GLOBAL SETTINGS (Tank / Injector) based on Mode
                            if mixingMode == .batch {
                                InputSlider(
                                    label: "Tank Size",
                                    value: $tankSize,
                                    range: 5...500,
                                    step: 5,
                                    displayValue: "\(Int(tankSize)) gal",
                                    color: Theme.emerald500
                                )
                            } else if mixingMode == .downstream {
                                InputSlider(
                                    label: "Injector Ratio",
                                    value: $injectorRatio,
                                    range: 4...20,
                                    step: 1,
                                    displayValue: "1:\(Int(injectorRatio))",
                                    color: Theme.amber500
                                )
                            }
                            
                            Divider().background(Theme.slate700)
                            
                            // 2. CHEMICAL SPECIFIC SETTINGS
                            switch strategy {
                            case .targetPercentage:
                                InputSlider(
                                    label: "Target Strength",
                                    value: $targetPercentage,
                                    range: 0.5...6.0,
                                    step: 0.1,
                                    displayValue: String(format: "%.1f%%", targetPercentage),
                                    color: Theme.sky500
                                )
                                VStack(alignment: .leading) {
                                    Text("Source SH Strength: \(String(format: "%.1f", sourceSH))%")
                                        .font(.caption)
                                        .foregroundColor(Theme.slate400)
                                    Slider(value: $sourceSH, in: 10...15, step: 0.5)
                                        .tint(Theme.slate400)
                                }
                                
                            case .dilutionRatio(_):
                                InputSlider(
                                    label: "Dilution Ratio (Water:Chem)",
                                    value: $dilutionRatio,
                                    range: 1...20,
                                    step: 1,
                                    displayValue: "\(Int(dilutionRatio)):1",
                                    color: Theme.purple500
                                )
                                
                            case .ozPerGallon(_):
                                InputSlider(
                                    label: "Ounces per Gallon",
                                    value: $ozPerGallon,
                                    range: 0.5...10,
                                    step: 0.5,
                                    displayValue: String(format: "%.1f oz", ozPerGallon),
                                    color: Theme.pink500
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Results
                    ResultsView(
                        mode: mixingMode,
                        strategy: strategy,
                        tankSize: tankSize,
                        injectorRatio: injectorRatio,
                        targetPercent: targetPercentage,
                        sourceSH: sourceSH,
                        dilutionRatio: dilutionRatio,
                        ozPerGal: ozPerGallon
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top)
        }
    }
    
    private func updateDefaults(for chemical: Chemical) {
        switch chemical.mixingStrategy {
        case .dilutionRatio(let defaultRatio):
            self.dilutionRatio = defaultRatio
        case .ozPerGallon(let defaultOz):
            self.ozPerGallon = defaultOz
        case .targetPercentage:
            self.targetPercentage = 1.5 // Default SH clean
        default: break
        }
    }
}

struct InputSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let displayValue: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                    .foregroundColor(Theme.slate50)
                Spacer()
                Text(displayValue)
                    .font(Theme.headingFont)
                    .foregroundColor(color)
            }
            Slider(value: $value, in: range, step: step)
                .tint(color)
        }
    }
}

struct ResultsView: View {
    let mode: MixingMode
    let strategy: MixingStrategy
    
    // Inputs
    let tankSize: Double
    let injectorRatio: Double
    let targetPercent: Double
    let sourceSH: Double
    let dilutionRatio: Double
    let ozPerGal: Double
    
    var body: some View {
        VStack(spacing: 16) {
            switch mode {
            case .batch:
                batchCalculation
            case .downstream:
                downstreamCalculation
            case .manifold:
                manifoldCalculation
            }
        }
    }
    
    // MARK: - Batch Calculations
    @ViewBuilder
    var batchCalculation: some View {
        switch strategy {
        case .targetPercentage:
            // SH Formula: (Target / Source) * Tank
            let shNeeded = (targetPercent / sourceSH) * tankSize
            let waterNeeded = tankSize - shNeeded
            
            HStack(spacing: 12) {
                ResultCard(title: "SH Needed", value: fmt(shNeeded), unit: "GAL", color: Theme.sky500)
                ResultCard(title: "Water Needed", value: fmt(waterNeeded), unit: "GAL", color: Theme.emerald500)
            }
            
        case .dilutionRatio:
            // Ratio 4:1 means 5 parts total. Chem = 1/5.
            let totalParts = dilutionRatio + 1
            let chemNeeded = tankSize / totalParts
            let waterNeeded = tankSize - chemNeeded
            
            HStack(spacing: 12) {
                ResultCard(title: "Chem Needed", value: fmt(chemNeeded), unit: "GAL", color: Theme.purple500)
                ResultCard(title: "Water Needed", value: fmt(waterNeeded), unit: "GAL", color: Theme.emerald500)
            }
            
        case .ozPerGallon:
            // Simple: Tank * Oz
            let totalOz = tankSize * ozPerGal
            
            ResultCard(title: "Chem Needed", value: fmt(totalOz), unit: "OZ", color: Theme.pink500)
        }
    }
    
    // MARK: - Downstream Calculations
    @ViewBuilder
    var downstreamCalculation: some View {
        switch strategy {
        case .targetPercentage:
            // Max hitting the wall = Source / (Injector + 1)
            let hittingWall = sourceSH / (injectorRatio + 1)
            let isPossible = targetPercent <= hittingWall
            
            GlassCard {
                VStack {
                    Text("AT THE TIP")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                    
                    Text("\(String(format: "%.2f", hittingWall))%")
                        .font(Theme.headingFont.weight(.heavy))
                        .font(.system(size: 48))
                        .foregroundColor(Theme.amber500)
                        .shadow(color: Theme.amber500.opacity(0.5), radius: 10)
                    
                    if !isPossible {
                        Text("Target \(String(format: "%.1f", targetPercent))% is unreachable")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
        case .dilutionRatio:
            // Injector does 10:1 (roughly 9% chem).
            // If we need 4:1 (20% chem), we can't do it unless we boost source? 
            // Usually downstream is fixed. Let's show the final ratio at tip.
            // Ratio at tip = InjectorRatio + (InjectorRatio * SourceDilution?? No)
            // Just injector ratio.
            
            let tipRatio = injectorRatio
            let percentStrength = 1.0 / (injectorRatio + 1) * 100
            
            GlassCard {
                VStack(spacing: 8) {
                    Text("FINAL DILUTION")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                    Text("1:\(Int(tipRatio))")
                        .font(Theme.headingFont).font(.title)
                        .foregroundColor(Theme.amber500)
                    Text("Approx \(fmt(percentStrength))% Strength")
                        .font(.caption).foregroundColor(Theme.slate500)
                }
                .frame(maxWidth: .infinity).padding()
            }
            
        case .ozPerGallon:
            // Injector pulls 1 gal chem per X gal water.
            // Result is fixed.
            let ozPerGalAtTip = 128.0 / (injectorRatio + 1)
            
            ResultCard(title: "Oz/Gal at Tip", value: fmt(ozPerGalAtTip), unit: "OZ", color: Theme.pink500)
        }
    }
    
    // MARK: - Manifold Calculations
    @ViewBuilder
    var manifoldCalculation: some View {
        // Simple dial logic assumption: Dial 0-10 represents 0-100% flow relative to water?
        // Or ratio. Simplification:
        // SH: Target / Source * 10
        // Surfactant: Oz / 5 * 10?? (Heuristic)
        
        switch strategy {
        case .targetPercentage:
            let dial = (targetPercent / sourceSH) * 10
            HStack {
                ResultCard(title: "SH Dial", value: fmt(dial), unit: "/ 10", color: Theme.sky500)
                ResultCard(title: "Water Dial", value: "10", unit: "/ 10", color: Theme.emerald500)
            }
            
        case .dilutionRatio:
            // Needs 4:1. 
            // Water = 10 (Max input). Chem needs to be 1/4th of Water flow? No, 4:1 means 4 water 1 chem.
            // So Chem Dial = WaterDial / Ratio.
            let chemDial = 10.0 / dilutionRatio
            
            HStack {
                ResultCard(title: "Chem Dial", value: fmt(chemDial), unit: "/ 10", color: Theme.purple500)
                ResultCard(title: "Water Dial", value: "10", unit: "/ 10", color: Theme.emerald500)
            }
            
        case .ozPerGallon:
            // 1 oz per gallon. 1 gallon = 128 oz.
            // Ratio approx 1:128.
            // Very low dial setting.
            // let dial = (ozPerGal / 128.0) * 10 * 10 
            // This is vague without specific manifold specs. Let's just show Oz info.
            
            ResultCard(title: "Metering Valve", value: "LOW", unit: "\(fmt(ozPerGal)) oz/gal", color: Theme.pink500)
        }
    }
    
    func fmt(_ val: Double) -> String {
        return String(format: "%.1f", val)
    }
}

struct ResultCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        GlassCard {
            VStack(spacing: 4) {
                Text(title)
                    .font(Theme.labelFont)
                    .foregroundColor(Theme.slate400)
                    .multilineTextAlignment(.center)
                
                Text(value)
                    .font(Theme.headingFont)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.3), radius: 8)
                
                Text(unit)
                    .font(Theme.labelFont)
                    .foregroundColor(Theme.slate500)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

struct ARMeasurePlaceholder: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(Theme.sky500.opacity(0.5))
            Text("AR Measurement Coming Soon")
                .font(Theme.headingFont)
                .foregroundColor(Theme.slate400)
                .padding()
            Spacer()
        }
    }
}
