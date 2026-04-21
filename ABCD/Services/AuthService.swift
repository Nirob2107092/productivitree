//
//  AuthService.swift
//  ABCD
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthService: ObservableObject {
    @Published var currentUser: FirebaseAuth.User?
    @Published var userModel: UserModel?
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var userDocumentListener: ListenerRegistration?

    init() {
        listenToAuthState()
    }

    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        userDocumentListener?.remove()
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

    func register(email: String, password: String, displayName: String, completion: ((Bool) -> Void)? = nil) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion?(false)
                    return
                }

                guard let firebaseUser = result?.user else {
                    self?.errorMessage = "Registration failed. Please try again."
                    completion?(false)
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
                completion?(true)
            }
        }
    }

    // MARK: - Login

    func login(email: String, password: String, completion: ((Bool) -> Void)? = nil) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion?(false)
                    return
                }
                self?.errorMessage = nil
                completion?(true)
            }
        }
    }

    // MARK: - Logout

    func logout() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.userDocumentListener?.remove()
                self.userDocumentListener = nil
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
        let data: [String: Any] = [
            "id": user.id,
            "email": user.email,
            "displayName": user.displayName,
            "xp": user.xp,
            "level": user.level,
            "tasksCompleted": user.tasksCompleted,
            "totalFocusMinutes": user.totalFocusMinutes,
            "createdAt": Timestamp(date: user.createdAt),
            "treeLevel": user.treeLevel,
            "treeStage": user.treeStage.rawValue,
            "environment": user.environment.rawValue,
            "lastTreeUpdate": user.lastTreeUpdate.map(Timestamp.init(date:)) ?? NSNull()
        ]

        db.collection(Constants.Collections.users)
            .document(user.id)
            .setData(data) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "Failed to create user profile: \(error.localizedDescription)"
                        return
                    }
                    self?.userModel = user
                    self?.errorMessage = nil
                }
            }
    }

    func fetchUserDocument(userId: String) {
        userDocumentListener?.remove()

        userDocumentListener = db.collection(Constants.Collections.users)
            .document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }

                    guard let snapshot = snapshot, snapshot.exists,
                          let data = snapshot.data() else {
                        self?.errorMessage = "User profile not found."
                        return
                    }

                    let createdTimestamp = data["createdAt"] as? Timestamp
                    let lastTreeUpdateTimestamp = data["lastTreeUpdate"] as? Timestamp
                    let treeStageRaw = data["treeStage"] as? String
                    let environmentRaw = data["environment"] as? String
                    let user = UserModel(
                        id: data["id"] as? String ?? userId,
                        email: data["email"] as? String ?? "",
                        displayName: data["displayName"] as? String ?? "",
                        xp: data["xp"] as? Int ?? 0,
                        level: data["level"] as? Int ?? 0,
                        tasksCompleted: data["tasksCompleted"] as? Int ?? 0,
                        totalFocusMinutes: data["totalFocusMinutes"] as? Int ?? 0,
                        createdAt: createdTimestamp?.dateValue() ?? Date(),
                        treeLevel: data["treeLevel"] as? Int ?? 1,
                        treeStage: TreeStage(rawValue: treeStageRaw ?? "") ?? .seed,
                        environment: EnvironmentType(rawValue: environmentRaw ?? "") ?? .normal,
                        lastTreeUpdate: lastTreeUpdateTimestamp?.dateValue()
                    )
                    self?.userModel = user
                }
            }
    }
}
