import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var animateGradient = false
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    enum LegalType: Identifiable {
        case terms, privacy
        var id: Self { self }
    }
    
    @State private var activeLegalSheet: LegalType?
    
    var body: some View {
        ZStack {
            // 1. Animated Animated Background
            LinearGradient(colors: [Theme.slate900, Color(hex: "0F172A"), Color(hex: "1E293B")], startPoint: animateGradient ? .topLeading : .bottomLeading, endPoint: animateGradient ? .bottomTrailing : .topTrailing)
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
            
            // Mesh Gradient / Orb Effects (Simulated with Blur)
            Circle()
                .fill(Theme.sky500.opacity(0.2))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(Theme.purple500.opacity(0.2))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: 100, y: 300)
            
            VStack(spacing: 30) {
                Spacer()
                
                // 2. Logo / Branding
                VStack(spacing: 12) {
                    AppLogoView(size: 140)
                        .padding(.top, 40)
                    
                    Text("Pressure Washing Pro")
                        .font(.system(size: 44, weight: .bold, design: .serif)) // Elegant Serif
                        .italic()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                }
                
                // 3. Value Proposition / Trial
                VStack(spacing: 8) {
                    Text("Clean Smarter. Work Faster. Get Paid.")
                        .font(Theme.headingFont)
                        .foregroundColor(Theme.emerald500)
                        .multilineTextAlignment(.center)
                        .shadow(color: Theme.emerald500.opacity(0.5), radius: 10)
                    
                    Text("Start Your 7-Day Free Trial")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                }
                .padding(.bottom, 20)
                
                // 4. Login Form
                GlassCard {
                    VStack(spacing: 20) {
                        // Email Field
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(Theme.slate500)
                            TextField("Email Address", text: $email)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Theme.slate800)
                        .cornerRadius(12)
                        
                        // Password Field
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(Theme.slate500)
                            SecureField("Password", text: $password)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Theme.slate800)
                        .cornerRadius(12)
                        
                        Divider().background(Theme.slate700)
                        
                        // Login Button
                        Button(action: {
                            isLoggingIn = true
                            authManager.login() // Simulate login
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.primaryGradient)
                                
                                if isLoggingIn {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Start Free Trial")
                                        .font(Theme.headingFont)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(height: 50)
                            .shadow(color: Theme.sky500.opacity(0.4), radius: 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                
                // 5. Social Auth
                VStack(spacing: 16) {
                    Text("Or continue with")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate500)
                    
                    HStack(spacing: 20) {
                        SocialButton(icon: "apple.logo", title: "Apple") {
                            authManager.login()
                        }
                        
                        SocialButton(icon: "g.circle.fill", title: "Google") {
                            authManager.login()
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Button("Terms of Service") { activeLegalSheet = .terms }
                    Text("&")
                    Button("Privacy Policy") { activeLegalSheet = .privacy }
                }
                .font(.caption2)
                .foregroundColor(Theme.slate500)
                .underline()
                .buttonStyle(.plain)
                .padding()
            }
        }
        .sheet(item: $activeLegalSheet) { type in
            switch type {
            case .terms: 
                TermsAndConditionsView()
                    .environmentObject(authManager)
            case .privacy: 
                PrivacyPolicyView()
            }
        }
    }
}

struct SocialButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(Theme.labelFont)
            }
            .frame(width: 140, height: 44)
            .background(Theme.slate800.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.slate700, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
