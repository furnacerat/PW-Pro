import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var currentPage = 0
    @State private var businessNameInput = ""
    @State private var showingClientSheet = false
    @State private var showingJobSheet = false
    @State private var animateCheckmarks = false
    
    var body: some View {
        ZStack {
            // Background
            IndustrialBackground()
            
            // Floating orbs for depth
            Circle()
                .fill(Theme.sky500.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -120, y: -200)
                .floating(amplitude: 10, duration: 4.0)
            
            Circle()
                .fill(Theme.emerald500.opacity(0.12))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: 100, y: 250)
                .floating(amplitude: 15, duration: 5.0)
            
            VStack(spacing: 0) {
                if !onboardingManager.hasSeenWalkthrough {
                    WalkthroughView(onComplete: {
                        withAnimation(.spring()) {
                            onboardingManager.markWalkthroughComplete()
                        }
                    }, onSkip: {
                        onboardingManager.skipOnboarding()
                    })
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
                } else {
                    // Existing Checklist Content
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 16) {
                            AppLogoView(size: 80)
                                .glow(color: Theme.sky500, radius: 15)
                            
                            Text("Welcome to PWPro!")
                                .font(Theme.industrialHeading)
                                .foregroundColor(.white)
                            
                            Text("Let's get your business set up in just a few steps")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.slate400)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 40)
                        
                        // Progress indicator
                        ProgressBar(progress: onboardingManager.completionPercentage)
                            .frame(height: 8)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 8)
                        
                        Text("\(Int(onboardingManager.completionPercentage * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(Theme.slate500)
                            .padding(.bottom, 30)
                        
                        // Checklist
                        VStack(spacing: 16) {
                            OnboardingChecklistItem(
                                title: "Name Your Business",
                                subtitle: "What should we call your company?",
                                icon: "building.2.fill",
                                isComplete: onboardingManager.hasAddedBusinessName,
                                action: { currentPage = 1 }
                            )
                            
                            OnboardingChecklistItem(
                                title: "Add Your First Client",
                                subtitle: "Start building your customer base",
                                icon: "person.fill.badge.plus",
                                isComplete: onboardingManager.hasCreatedFirstClient,
                                action: { showingClientSheet = true }
                            )
                            .disabled(!onboardingManager.hasAddedBusinessName)
                            .opacity(onboardingManager.hasAddedBusinessName ? 1 : 0.5)
                            
                            OnboardingChecklistItem(
                                title: "Book Your First Job",
                                subtitle: "Schedule your first appointment",
                                icon: "calendar.badge.plus",
                                isComplete: onboardingManager.hasBookedFirstJob,
                                action: { showingJobSheet = true }
                            )
                            .disabled(!onboardingManager.hasCreatedFirstClient)
                            .opacity(onboardingManager.hasCreatedFirstClient ? 1 : 0.5)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // Bottom actions
                        VStack(spacing: 16) {
                            if onboardingManager.allStepsCompleted {
                                LuxuryButton(
                                    title: "Start Using PWPro",
                                    icon: "arrow.right.circle.fill",
                                    gradient: Theme.primaryGradient
                                ) {
                                    onboardingManager.completeOnboarding()
                                }
                                .padding(.horizontal)
                            }
                            
                            Button("Skip for now") {
                                onboardingManager.skipOnboarding()
                            }
                            .font(.subheadline)
                            .foregroundColor(Theme.slate500)
                        }
                        .padding(.bottom, 40)
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            
            // Business Name Input Sheet
            if currentPage == 1 {
                BusinessNameInputView(
                    businessName: $businessNameInput,
                    onSave: {
                        onboardingManager.saveBusinessName(businessNameInput)
                        withAnimation(.spring()) {
                            currentPage = 0
                        }
                    },
                    onCancel: {
                        withAnimation(.spring()) {
                            currentPage = 0
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showingClientSheet) {
            QuickAddClientView(onComplete: {
                onboardingManager.markClientCreated()
                showingClientSheet = false
            })
        }
        .sheet(isPresented: $showingJobSheet) {
            QuickJobBookingView(onComplete: {
                onboardingManager.markJobBooked()
                showingJobSheet = false
            })
        }
        .onAppear {
            businessNameInput = onboardingManager.businessName
        }
    }
}

// MARK: - Supporting Views

struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.slate800)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [Theme.sky500, Theme.emerald500],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
        }
    }
}

struct OnboardingChecklistItem: View {
    let title: String
    let subtitle: String
    let icon: String
    let isComplete: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if !isComplete {
                HapticManager.medium()
                action()
            }
        }) {
            HStack(spacing: 16) {
                // Checkbox
                ZStack {
                    Circle()
                        .fill(isComplete ? Theme.emerald500 : Theme.slate800)
                        .frame(width: 44, height: 44)
                    
                    if isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(Theme.slate500)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(isComplete ? Theme.emerald500 : Theme.slate700, lineWidth: 2)
                )
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isComplete ? Theme.slate400 : .white)
                        .strikethrough(isComplete, color: Theme.slate500)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Theme.slate500)
                }
                
                Spacer()
                
                if !isComplete {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Theme.slate500)
                        .font(.caption)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isComplete ? Theme.emerald500.opacity(0.1) : Theme.slate800.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isComplete ? Theme.emerald500.opacity(0.3) : Theme.slate700, lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct BusinessNameInputView: View {
    @Binding var businessName: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }
            
            GlassCard {
                VStack(spacing: 24) {
                    Text("What's your business name?")
                        .font(Theme.headingFont)
                        .foregroundColor(.white)
                    
                    TextField("e.g., Clean Pro Washing", text: $businessName)
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding()
                        .background(Theme.slate800)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.slate700, lineWidth: 1)
                        )
                    
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            onCancel()
                        }
                        .foregroundColor(Theme.slate400)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.slate800)
                        .cornerRadius(12)
                        
                        Button("Save") {
                            if !businessName.isEmpty {
                                onSave()
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(businessName.isEmpty ? Theme.slate700 : Theme.sky500)
                        .cornerRadius(12)
                        .disabled(businessName.isEmpty)
                    }
                }
            }
            .padding(24)
        }
    }
}

struct QuickAddClientView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var address = ""
    let onComplete: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.slate900.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        GlassCard {
                            VStack(spacing: 16) {
                                QuickInputField(title: "Name", placeholder: "John Smith", text: $name)
                                QuickInputField(title: "Phone", placeholder: "(555) 123-4567", text: $phone)
                                QuickInputField(title: "Email", placeholder: "john@email.com", text: $email)
                                QuickInputField(title: "Address", placeholder: "123 Main St", text: $address)
                            }
                        }
                        .padding()
                        
                        LuxuryButton(title: "Add Client", icon: "person.fill.badge.plus") {
                            let newClient = Client(
                                name: name,
                                email: email,
                                phone: phone,
                                address: address,
                                status: .lead,
                                tags: [],
                                jobHistory: [],
                                interactions: []
                            )
                            Task {
                                await ClientManager.shared.addClient(newClient)
                            }
                            onComplete()
                        }
                        .padding(.horizontal)
                        .disabled(name.isEmpty)
                        .opacity(name.isEmpty ? 0.5 : 1)
                    }
                }
            }
            .navigationTitle("Add Your First Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.slate400)
                }
            }
        }
    }
}

struct QuickJobBookingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var scheduler = SchedulingManager.shared
    @State private var clientName = ""
    @State private var clientAddress = ""
    @State private var scheduledDate = Date()
    @State private var durationHours = 2.0
    @State private var notes = ""
    let onComplete: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.slate900.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Client Details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("CLIENT DETAILS")
                                .font(Theme.labelFont)
                                .foregroundColor(Theme.slate500)
                            
                            GlassCard {
                                VStack(spacing: 16) {
                                    QuickInputField(title: "Client Name", placeholder: "John Smith", text: $clientName)
                                    QuickInputField(title: "Address", placeholder: "123 Main St", text: $clientAddress)
                                }
                            }
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
                        
                        LuxuryButton(title: "Book Job", icon: "calendar.badge.plus") {
                            var job = ScheduledJob(
                                invoiceID: UUID(),
                                clientName: clientName,
                                clientAddress: clientAddress,
                                scheduledDate: scheduledDate
                            )
                            job.durationHours = durationHours
                            job.notes = notes
                            scheduler.jobs.append(job)
                            HapticManager.success()
                            onComplete()
                        }
                        .disabled(clientName.isEmpty || clientAddress.isEmpty)
                        .opacity((clientName.isEmpty || clientAddress.isEmpty) ? 0.5 : 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("Book Your First Job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.slate400)
                }
            }
        }
    }
}

struct QuickInputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(Theme.labelFont)
                .foregroundColor(Theme.slate500)
            
            TextField(placeholder, text: $text)
                .font(Theme.bodyFont)
                .foregroundColor(.white)
                .padding()
                .background(Theme.slate800)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.slate700, lineWidth: 1)
                )
        }
    }
}

struct WalkthroughSlide: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct WalkthroughView: View {
    let onComplete: () -> Void
    let onSkip: () -> Void
    @State private var selection = 0
    
    let slides = [
        WalkthroughSlide(
            title: "Smart Estimator",
            description: "Calculate surface areas instantly with our camera-based AI tools. Create professional quotes in seconds.",
            icon: "camera.viewfinder",
            color: Theme.sky500
        ),
        WalkthroughSlide(
            title: "Field Tools & Mixes",
            description: "Access our advanced chemical mix calculator and real-time weather analytics optimized for your job site.",
            icon: "beaker.fill",
            color: Theme.emerald500
        ),
        WalkthroughSlide(
            title: "Business Suite",
            description: "Manage leads, schedule jobs, and track your profit & loss with our high-end CRM and accounting dashboard.",
            icon: "chart.bar.xaxis",
            color: Theme.amber500
        ),
        WalkthroughSlide(
            title: "Estimate Sharing",
            description: "Send professional estimates via SMS or Email. Let customers approve or request changes instantly.",
            icon: "paperplane.fill",
            color: Theme.sky500
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Skip") { onSkip() }
                    .foregroundColor(Theme.slate500)
                Spacer()
                AppLogoView(size: 40)
            }
            .padding()
            
            TabView(selection: $selection) {
                ForEach(0..<slides.count, id: \.self) { index in
                    VStack(spacing: 30) {
                        // Icon Circle
                        ZStack {
                            Circle()
                                .fill(slides[index].color.opacity(0.1))
                                .frame(width: 180, height: 180)
                            
                            Circle()
                                .stroke(slides[index].color.opacity(0.3), lineWidth: 2)
                                .frame(width: 200, height: 200)
                            
                            Image(systemName: slides[index].icon)
                                .font(.system(size: 80))
                                .foregroundColor(slides[index].color)
                                .glow(color: slides[index].color, radius: 10)
                        }
                        .floating(amplitude: 15, duration: Double.random(in: 3...5))
                        
                        VStack(spacing: 16) {
                            Text(slides[index].title)
                                .font(Theme.industrialHeading)
                                .foregroundColor(.white)
                            
                            Text(slides[index].description)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.slate400)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .lineSpacing(4)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom Page Indicator
            HStack(spacing: 8) {
                ForEach(0..<slides.count, id: \.self) { index in
                    Capsule()
                        .fill(selection == index ? slides[selection].color : Theme.slate700)
                        .frame(width: selection == index ? 24 : 8, height: 8)
                        .animation(.spring(), value: selection)
                }
            }
            .padding(.bottom, 40)
            
            // Action Button
            LuxuryButton(
                title: selection == slides.count - 1 ? "Let's Get Started" : "Next",
                icon: selection == slides.count - 1 ? "checkmark.circle.fill" : "arrow.right",
                gradient: selection == slides.count - 1 ? Theme.primaryGradient : LinearGradient(colors: [Theme.slate700, Theme.slate800], startPoint: .top, endPoint: .bottom)
            ) {
                if selection == slides.count - 1 {
                    onComplete()
                } else {
                    withAnimation {
                        selection += 1
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }
}


