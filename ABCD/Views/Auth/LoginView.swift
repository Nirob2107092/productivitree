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

                // App branding
                VStack(spacing: 8) {
                    Image(systemName: "tree.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("Productivitree")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Grow your productivity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Input fields
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

                // Error message
                if let error = authService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Login button
                Button {
                    login()
                } label: {
                    Text("Log In")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(isLoading)

                // Navigate to Register
                Button {
                    showRegister = true
                } label: {
                    Text("Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }

                Spacer()
            }
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
