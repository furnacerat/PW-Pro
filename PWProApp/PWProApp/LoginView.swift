import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var animateGradient = false
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    @State private var isSignupMode = true // Default to signup for new users
    enum LegalType: Identifiable {
        case terms, privacy
        var id: Self { self }
    }
    
    @State private var activeLegalSheet: LegalType?
    
    var body: some View {
        ZStack {
            // Premium Industrial Background
            IndustrialBackground()
            
            // Floating orbs for depth
            Circle()
                .fill(Theme.sky500.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: -100, y: -250)
                .floating(amplitude: 15, duration: 4.0)
            
            Circle()
                .fill(Theme.emerald500.opacity(0.12))
                .frame(width: 350, height: 350)
                .blur(radius: 70)
                .offset(x: 120, y: 350)
                .floating(amplitude: 20, duration: 5.0)
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo / Branding with premium effects
                VStack(spacing: 16) {
                    AppLogoView(size: 140)
                        .glow(color: Theme.sky500, radius: 20)
                        .floating(amplitude: 8, duration: 3.0)
                        .padding(.top, 40)
                    
                    Text("Pressure Washing Pro")
                        .font(.system(size: 44, weight: .bold, design: .serif))
                        .italic()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(.horizontal, 20)
                        .shadow(color: Theme.sky500.opacity(0.5), radius: 10, x: 0, y: 4)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                }
                
                // Value Proposition with shimmer
                VStack(spacing: 8) {
                    Text("Clean Smarter. Work Faster. Get Paid.")
                        .font(Theme.industrialSubheading)
                        .foregroundColor(Theme.emerald500)
                        .multilineTextAlignment(.center)
                        .glow(color: Theme.emerald500, radius: 15)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.sky400)
                        Text("Start Your 7-Day Free Trial")
                            .font(Theme.labelText)
                            .foregroundColor(Theme.slate300)
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.sky400)
                    }
                    .shimmer(duration: 3.0)
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
                        
                        // Error Message with high visibility
                        if let error = authManager.error {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error)
                                    .font(.caption)
                            }
                            .foregroundColor(Theme.red500)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.red500.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.red500.opacity(0.3), lineWidth: 1))
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Signup/Login Button - Premium Version
                        LuxuryButton(
                            title: isSignupMode ? "Start Free Trial" : "Sign In",
                            icon: isSignupMode ? "sparkles" : "arrow.right.circle.fill",
                            gradient: Theme.primaryGradient,
                            isLoading: authManager.isLoading
                        ) {
                            Task {
                                if isSignupMode {
                                    await authManager.signUp(email: email, password: password)
                                } else {
                                    await authManager.login(email: email, password: password)
                                }
                            }
                        }
                        
                        // Toggle between signup and login - more prominent
                        Button(action: {
                            withAnimation(.spring()) {
                                isSignupMode.toggle()
                                authManager.error = nil // Clear error when switching modes
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text(isSignupMode ? "Already have an account?" : "Don't have an account?")
                                    .foregroundColor(Theme.slate400)
                                Text(isSignupMode ? "Sign In Instead" : "Create Now")
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.sky500)
                            }
                            .font(.caption)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .padding(.top, 8)
                        
                        #if DEBUG
                        // NEW: Demo Access Bypass
                        Button(action: {
                            authManager.developerBypass()
                        }) {
                            HStack {
                                Image(systemName: "sparkles.rectangle.stack.fill")
                                Text("Preview App (Skip Login)")
                                    .fontWeight(.bold)
                            }
                            .font(.caption2)
                            .foregroundColor(Theme.emerald500.opacity(0.8))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Theme.emerald500.opacity(0.1))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Theme.emerald500.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.top, 24)
                        .buttonStyle(PressableButtonStyle())
                        #endif
                    }
                }
                .padding(.horizontal)
                
                // 5. Social Auth (Removed as requested)
                /*
                VStack(spacing: 16) {
                    Text("Or continue with")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate500)
                    
                    HStack(spacing: 20) {
                        SocialButton(icon: "apple.logo", title: "Apple") {
                            // TODO: Implement Apple Sign In with Supabase
                        }
                        
                        SocialButton(icon: "g.circle.fill", title: "Google") {
                            // TODO: Implement Google Sign In with Supabase
                        }
                    }
                }
                */
                
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
