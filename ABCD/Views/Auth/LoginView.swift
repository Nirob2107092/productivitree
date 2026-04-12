//
//  LoginView.swift
//  ABCD
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
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
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
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

                // Login button
                Button {
                    viewModel.login()
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
                .disabled(viewModel.isLoading)

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
                RegisterView(viewModel: viewModel)
            }
        }
    }
}
