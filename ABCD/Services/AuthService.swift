//
//  AuthService.swift
//  ABCD
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService: ObservableObject {
    @Published var currentUser: FirebaseAuth.User?
    @Published var userModel: UserModel?
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        listenToAuthState()
    }

    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Auth State Listener

    func listenToAuthState() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                if let user = user {
                    self?.fetchUserDocument(userId: user.uid)
                } else {
                    self?.userModel = nil
                }
            }
        }
    }

    // MARK: - Register

    func register(email: String, password: String, displayName: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }

                guard let firebaseUser = result?.user else {
                    self?.errorMessage = "Registration failed. Please try again."
                    return
                }

                let newUser = UserModel(
                    id: firebaseUser.uid,
                    email: email,
                    displayName: displayName,
                    xp: 0,
                    level: 0,
                    tasksCompleted: 0,
                    totalFocusMinutes: 0,
                    createdAt: Date()
                )

                self?.createUserDocument(user: newUser)
            }
        }
    }

    // MARK: - Login

    func login(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                self?.errorMessage = nil
            }
        }
    }

    // MARK: - Logout

    func logout() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.currentUser = nil
                self.userModel = nil
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Firestore Helpers

    func createUserDocument(user: UserModel) {
        do {
            try db.collection(Constants.Collections.users)
                .document(user.id)
                .setData(from: user)
            DispatchQueue.main.async {
                self.userModel = user
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create user profile: \(error.localizedDescription)"
            }
        }
    }

    func fetchUserDocument(userId: String) {
        db.collection(Constants.Collections.users)
            .document(userId)
            .getDocument { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }

                    guard let snapshot = snapshot, snapshot.exists else {
                        self?.errorMessage = "User profile not found."
                        return
                    }

                    do {
                        let user = try snapshot.data(as: UserModel.self)
                        self?.userModel = user
                    } catch {
                        self?.errorMessage = "Failed to parse user profile: \(error.localizedDescription)"
                    }
                }
            }
    }
}
