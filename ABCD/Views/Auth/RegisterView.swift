//
//  RegisterView.swift
//  ABCD
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 50))
                    .foregroundColor(.green)

                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Join Productivitree today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Input fields
            VStack(spacing: 16) {
                TextField("Display Name", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.name)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)
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

            // Register button
            Button {
                register()
            } label: {
                Text("Sign Up")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(isLoading)

            // Back to Login
            Button {
                dismiss()
            } label: {
                Text("Already have an account? Log In")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
            }
        }
    }

    private func register() {
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
            authService.errorMessage = "Please enter your name."
            return
        }
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            authService.errorMessage = "Please enter your email."
            return
        }
        guard password.count >= 6 else {
            authService.errorMessage = "Password must be at least 6 characters."
            return
        }
        guard password == confirmPassword else {
            authService.errorMessage = "Passwords do not match."
            return
        }
        isLoading = true
        authService.register(email: email, password: password, displayName: displayName) { _ in
            isLoading = false
        }
    }
}
