//
//  LoginView.swift
//  ABCD
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.accent.opacity(0.12))
                            .frame(width: 92, height: 92)

                        Image(systemName: "tree.fill")
                            .font(.system(size: 42))
                            .foregroundColor(Theme.Colors.accent)
                    }

                    Text("Productivitree")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Grow your productivity")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
                .appCard(fill: Theme.Colors.surfaceStrong)

                if let error = authService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    login()
                } label: {
                    Text("Log In")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.Gradients.accent)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal)
                .disabled(isLoading)

                Button {
                    showRegister = true
                } label: {
                    Text("Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.accent)
                }

                Spacer()
            }
            .padding(.horizontal)
            .background(Theme.Gradients.appBackground.ignoresSafeArea())
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }

    private func login() {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            authService.errorMessage = "Please enter your email."
            return
        }
        guard !password.isEmpty else {
            authService.errorMessage = "Please enter your password."
            return
        }
        isLoading = true
        authService.login(email: email, password: password) { _ in
            isLoading = false
        }
    }
}
