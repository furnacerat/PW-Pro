//
//  LoginView.swift
//  PW Pro
//
//  Created by GitHub Copilot on 1/19/26.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("trialExpiresAt") private var trialExpiresAt: String = ""

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "lock.shield")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.blue)

                Text("Welcome to PW Pro")
                    .font(.largeTitle)
                    .bold()

                Text("Sign in to continue")
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)

                    Button(action: signInWithEmail) {
                        Text("Sign in with Email")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)

                VStack(spacing: 12) {
                    Button(action: signInWithGoogle) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Sign in with Google")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                    SignInWithAppleButtonView { result in
                        // placeholder: treat success as logged in
                        switch result {
                        case .success:
                            completeSignIn()
                        case .failure(let err):
                            errorMessage = err.localizedDescription
                            showError = true
                        }
                    }
                    .frame(height: 44)
                    .cornerRadius(8)
                }
                .padding(.horizontal)

                Button(action: startFreeTrial) {
                    Text("Try Free for 7 Days")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                Spacer()

                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                HStack {
                    Text("Need an account?")
                    Button("Sign up") {
                        // placeholder
                        email = ""
                        password = ""
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }

    private func signInWithEmail() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email."
            showError = true
            return
        }
        // Placeholder: accept any non-empty email for now
        completeSignIn()
    }

    private func signInWithGoogle() {
        // Placeholder: real Google sign-in requires SDK; simulate success
        completeSignIn()
    }

    private func startFreeTrial() {
        let expires = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        let iso = ISO8601DateFormatter().string(from: expires)
        trialExpiresAt = iso
        completeSignIn()
    }

    private func completeSignIn() {
        isLoggedIn = true
        showError = false
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

// Simple wrapper to present an Apple sign-in button and return a lightweight success/failure.
struct SignInWithAppleButtonView: UIViewRepresentable {
    enum Result {
        case success
        case failure(Error)
    }

    var onComplete: (Result) -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let btn = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        btn.addTarget(context.coordinator, action: #selector(Coordinator.handlePress), for: .touchUpInside)
        return btn
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onComplete: (Result) -> Void

        init(onComplete: @escaping (Result) -> Void) {
            self.onComplete = onComplete
        }

        @objc func handlePress() {
            let req = ASAuthorizationAppleIDProvider().createRequest()
            req.requestedScopes = [.fullName, .email]
            let ctr = ASAuthorizationController(authorizationRequests: [req])
            ctr.delegate = self
            ctr.presentationContextProvider = self
            ctr.performRequests()
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            // Prefer the key window from an active window scene (no use of deprecated `windows`).
            if let keyWindow = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) {
                return keyWindow
            }

            // Fallback: attach a new UIWindow to the first available UIWindowScene.
            if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
                return UIWindow(windowScene: scene)
            }

            // Last resort (very unlikely) — return an empty anchor.
            return ASPresentationAnchor()
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            onComplete(.success)
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            onComplete(.failure(error))
        }
    }
}
