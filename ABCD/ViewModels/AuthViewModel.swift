//
//  AuthViewModel.swift
//  ABCD
//

import Foundation
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var displayName = ""
    @Published var isLoading = false

    let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    var isLoggedIn: Bool {
        authService.currentUser != nil
    }

    // MARK: - Register

    func register() {
        guard validateRegistration() else { return }
        isLoading = true
        authService.register(email: email, password: password, displayName: displayName)
        isLoading = false
        clearFields()
    }

    // MARK: - Login

    func login() {
        guard validateLogin() else { return }
        isLoading = true
        authService.login(email: email, password: password)
        isLoading = false
        clearFields()
    }

    // MARK: - Logout

    func logout() {
        authService.logout()
    }

    // MARK: - Validation

    private func validateRegistration() -> Bool {
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
            authService.errorMessage = "Please enter your name."
            return false
        }
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            authService.errorMessage = "Please enter your email."
            return false
        }
        guard password.count >= 6 else {
            authService.errorMessage = "Password must be at least 6 characters."
            return false
        }
        guard password == confirmPassword else {
            authService.errorMessage = "Passwords do not match."
            return false
        }
        return true
    }

    private func validateLogin() -> Bool {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            authService.errorMessage = "Please enter your email."
            return false
        }
        guard !password.isEmpty else {
            authService.errorMessage = "Please enter your password."
            return false
        }
        return true
    }

    private func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
    }
}
