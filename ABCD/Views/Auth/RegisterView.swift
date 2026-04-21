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

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.accent.opacity(0.12))
                        .frame(width: 92, height: 92)

                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 38))
                        .foregroundColor(Theme.Colors.accent)
                }

                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Join Productivitree today")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
            }

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
                register()
            } label: {
                Text("Sign Up")
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
                dismiss()
            } label: {
                Text("Already have an account? Log In")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.accent)
            }

            Spacer()
        }
        .padding(.horizontal)
        .background(Theme.Gradients.appBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Theme.Colors.accent)
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
