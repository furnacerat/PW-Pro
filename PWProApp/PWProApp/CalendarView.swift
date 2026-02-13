import SwiftUI

struct CalendarView: View {
    @StateObject var scheduler = SchedulingManager.shared
    @State private var selectedDate = Date()
    @State private var showingAddJob = false
    @State private var isOptimizing = false
    @State private var jobToDelete: ScheduledJob?
    @State private var showingDeleteConfirmation = false
    
    let calendar = Calendar.current
    let daysInWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                // Header
                HStack {
                    Text("CALENDAR")
                        .font(Theme.headingFont)
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        showingAddJob = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.sky500)
                    }
                }
                .padding(.bottom, 8)
                
                // Calendar Grid Card
                GlassCard {
                    VStack(spacing: 20) {
                        // Month Selector
                        HStack {
                            Text(selectedDate, format: .dateTime.month(.wide).year())
                                .font(Theme.bodyFont)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                            HStack(spacing: 20) {
                                Button { moveMonth(by: -1) } label: { 
                                    Image(systemName: "chevron.left")
                                        .frame(width: 44, height: 44)
                                }
                                Button { moveMonth(by: 1) } label: { 
                                    Image(systemName: "chevron.right")
                                        .frame(width: 44, height: 44)
                                }
                            }
                            .foregroundColor(Theme.sky500)
                        }
                        
                        // Weekday Labels
                        HStack {
                            ForEach(daysInWeek, id: \.self) { day in
                                Text(day)
                                    .font(.caption2.bold())
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(Theme.slate500)
                            }
                        }
                        
                        // Days Grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(daysForMonth(), id: \.self) { date in
                                DayCell(date: date, 
                                       isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                       isToday: calendar.isDateInToday(date),
                                       hasJobs: !scheduler.jobs(for: date).isEmpty) {
                                    selectedDate = date
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // Jobs for Selected Day
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("JOBS FOR \(selectedDate, format: .dateTime.month().day())")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate400)
                        
                        Spacer()
                        
                        let dayJobs = scheduler.jobs(for: selectedDate)
                        if dayJobs.count >= 2 {
                            Button {
                                optimizeRoute()
                            } label: {
                                HStack(spacing: 4) {
                                    if isOptimizing {
                                        ProgressView().tint(Theme.sky500).scaleEffect(0.6)
                                    } else {
                                        Image(systemName: "sparkles")
                                    }
                                    Text(isOptimizing ? "Optimizing..." : "AI Optimize Route")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.sky500.opacity(0.1))
                                .foregroundColor(Theme.sky500)
                                .cornerRadius(4)
                            }
                            .disabled(isOptimizing)
                        }
                    }
                    
                    let dayJobs = scheduler.jobs(for: selectedDate)
                    if scheduler.isLoading {
                        // Skeleton loading state for jobs
                        VStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { _ in
                                SkeletonListItem()
                            }
                        }
                    } else if dayJobs.isEmpty {
                        GlassCard {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 36))
                                    .foregroundColor(Theme.sky500.opacity(0.5))
                                    .glow(color: Theme.sky500, radius: 8)
                                
                                Text("Nothing Scheduled")
                                    .font(Theme.headingFont)
                                    .foregroundColor(.white)
                                
                                Text("This day is free. Add a job to start building your schedule.")
                                    .font(.caption)
                                    .foregroundColor(Theme.slate400)
                                    .multilineTextAlignment(.center)
                                
                                Button {
                                    showingAddJob = true
                                    HapticManager.light()
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Job")
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Theme.sky500)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                            .padding(.vertical, 8)
                        }
                    } else {
                        VStack(spacing: 12) {
                            ForEach($scheduler.jobs) { $job in
                                if calendar.isDate(job.scheduledDate, inSameDayAs: selectedDate) {
                                    NavigationLink(destination: JobDetailView(job: $job)) {
                                        ScheduledJobRow(job: job)
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            jobToDelete = job
                                            showingDeleteConfirmation = true
                                            HapticManager.warning()
                                        } label: {
                                            Label("Delete Job", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Theme.slate900)
        .withErrorHandling(error: $scheduler.error)
        .alert("Delete Job?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                jobToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let job = jobToDelete {
                    scheduler.deleteJob(job)
                    jobToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this job? This action cannot be undone.")
        }
        .task {
            if scheduler.jobs.isEmpty {
                await scheduler.fetchJobs()
            }
        }
        .sheet(isPresented: $showingAddJob) {
            JobBookingView(invoice: nil)
        }
    }
    }
    
    
    private func moveMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func daysForMonth() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: monthInterval.start)) else { return [] }
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let startingDay = calendar.date(byAdding: .day, value: -(firstWeekday - 1), to: firstDay)!
        
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: startingDay) }
    }
    
    private func optimizeRoute() {
        let dayJobs = scheduler.jobs(for: selectedDate)
        guard dayJobs.count >= 2 else { return }
        
        isOptimizing = true
        
        Task {
            do {
                let jobData = dayJobs.map { (id: $0.id, address: $0.clientAddress) }
                let optimizedIds = try await GeminiManager.shared.optimizeRoute(jobs: jobData)
                

                
                await MainActor.run {
                    withAnimation {
                        // AI Optimization Result:
                        // The AI returns a list of Job IDs in the most efficient travel order.
                        // We re-sort the local `dayJobs` array to match this order so the
                        // user sees the optimal schedule immediately.
                        let dayJobIds = dayJobs.map { $0.id }
                        let otherJobs = scheduler.jobs.filter { !dayJobIds.contains($0.id) }
                        
                        let reorderedDayJobs = optimizedIds.compactMap { id in
                            dayJobs.first(where: { $0.id == id })
                        }
                        
                        // Ensure we don't lose any jobs if Gemini missed some
                        let missingIds = dayJobIds.filter { id in !optimizedIds.contains(id) }
                        let missingJobs = missingIds.compactMap { id in dayJobs.first(where: { $0.id == id }) }
                        
                        scheduler.jobs = otherJobs + reorderedDayJobs + missingJobs
                        
                        isOptimizing = false
                        HapticManager.success()
                    }
                }
            } catch {
                print("Route optimization failed: \(error)")
                await MainActor.run {
                    isOptimizing = false
                }
            }
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasJobs: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : (isToday ? Theme.sky500 : Theme.slate300))
                
                Circle()
                    .fill(hasJobs ? Theme.sky500 : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(isSelected ? Theme.sky500.opacity(0.2) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Theme.sky500 : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ScheduledJobRow: View {
    let job: ScheduledJob
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                // Time Pillar
                VStack(spacing: 4) {
                    Text(job.scheduledDate, format: .dateTime.hour().minute())
                        .font(Theme.dataMonospace)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.sky400)
                    
                    Text(job.status.rawValue.uppercased())
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(job.status.color.opacity(0.15))
                        .foregroundColor(job.status.color)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(job.status.color.opacity(0.3), lineWidth: 1)
                        )
                }
                .frame(width: 80)
                
                // Job Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.clientName)
                        .font(Theme.industrialSubheading)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        let weather = WeatherEngine.analyze(scheduledJob: job)
                        Image(systemName: weather.status.icon)
                            .font(.system(size: 10))
                            .foregroundColor(weather.status.color)
                            .glow(color: weather.status.color, radius: 4)
                        
                        Text(job.clientAddress)
                            .font(Theme.professionalBody)
                            .foregroundColor(Theme.slate400)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.slate500)
            }
        }
        .pressableCard()
    }
}
