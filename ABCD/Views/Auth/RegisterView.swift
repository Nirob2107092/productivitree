//
//  RegisterView.swift
//  ABCD
//

import SwiftUI

struct RegisterView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

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
                TextField("Display Name", text: $viewModel.displayName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.name)

                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)

                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)
            }
            .padding(.horizontal)

            // Error message
            if let error = viewModel.authService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Register button
            Button {
                viewModel.register()
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
            .disabled(viewModel.isLoading)

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
}
