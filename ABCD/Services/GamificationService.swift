//
//  GamificationService.swift
//  ABCD
//

import Foundation
import FirebaseFirestore
extension Notification.Name {
    static let didLevelUp = Notification.Name("didLevelUp")
}

class GamificationService {
    static let shared = GamificationService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Add XP

    func addXP(userId: String, amount: Int) {
        applyProgressUpdate(userId: userId, xpDelta: amount, tasksDelta: 0, activityAt: Date())
    }

    // MARK: - Increment Tasks Completed

    func incrementTasksCompleted(userId: String) {
        applyProgressUpdate(userId: userId, xpDelta: 0, tasksDelta: 1, activityAt: Date())
    }

    // MARK: - Task Completion (Single Write Path)

    func applyTaskCompletion(userId: String, xpAmount: Int) {
        applyProgressUpdate(userId: userId, xpDelta: xpAmount, tasksDelta: 1, activityAt: Date())
    }

    // MARK: - Non-XP Activity

    func registerActivity(userId: String, at date: Date = Date()) {
        applyProgressUpdate(userId: userId, xpDelta: 0, tasksDelta: 0, activityAt: date)
    }

    // MARK: - Internal

    private func applyProgressUpdate(userId: String, xpDelta: Int, tasksDelta: Int, activityAt: Date) {
        let userRef = db.collection(Constants.Collections.users).document(userId)

        fetchCurrentStreak(userId: userId) { [weak self] streak in
            guard let self else { return }

            self.db.runTransaction({ transaction, errorPointer -> Any? in
                do {
                    let snapshot = try transaction.getDocument(userRef)
                    let data = snapshot.data() ?? [:]

                    let currentXP = data["xp"] as? Int ?? 0
                    let oldLevel = data["level"] as? Int ?? (currentXP / Constants.XP.xpPerLevel)
                    let newXP = currentXP + xpDelta
                    let newLevel = newXP / Constants.XP.xpPerLevel

                    var user = self.userFromFirestore(userId: userId, data: data)
                    user.xp = newXP
                    user.level = newLevel
                    if tasksDelta > 0 {
                        user.tasksCompleted += tasksDelta
                    }

                    let treeService = TreeService(streak: streak, activityAt: activityAt)
                    let treeUpdatedUser = treeService.updateTreeState(for: user)

                    transaction.setData(self.firestoreData(from: treeUpdatedUser), forDocument: userRef, merge: true)

                    return [
                        "oldLevel": oldLevel,
                        "newLevel": newLevel,
                        "xp": newXP
                    ]
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }) { result, _ in
                guard let payload = result as? [String: Int] else { return }

                let oldLevel = payload["oldLevel"] ?? 0
                let newLevel = payload["newLevel"] ?? 0
                let xp = payload["xp"] ?? 0

                if newLevel > oldLevel {
                    NotificationCenter.default.post(
                        name: .didLevelUp,
                        object: nil,
                        userInfo: [
                            "userId": userId,
                            "newLevel": newLevel,
                            "xp": xp
                        ]
                    )
                }
            }
        }
    }

    private func fetchCurrentStreak(userId: String, completion: @escaping (Int) -> Void) {
        db.collection(Constants.Collections.habits)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, _ in
                let maxStreak = snapshot?.documents
                    .map { $0.data()["currentStreak"] as? Int ?? 0 }
                    .max() ?? 0

                completion(maxStreak)
            }
    }

    private func userFromFirestore(userId: String, data: [String: Any]) -> UserModel {
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let lastTreeUpdate = (data["lastTreeUpdate"] as? Timestamp)?.dateValue()
        let treeStage = TreeStage(rawValue: data["treeStage"] as? String ?? "") ?? .seed
        let environment = EnvironmentType(rawValue: data["environment"] as? String ?? "") ?? .normal

        return UserModel(
            id: data["id"] as? String ?? userId,
            email: data["email"] as? String ?? "",
            displayName: data["displayName"] as? String ?? "",
            xp: data["xp"] as? Int ?? 0,
            level: data["level"] as? Int ?? 0,
            tasksCompleted: data["tasksCompleted"] as? Int ?? 0,
            totalFocusMinutes: data["totalFocusMinutes"] as? Int ?? 0,
            createdAt: createdAt,
            treeLevel: data["treeLevel"] as? Int ?? 1,
            treeStage: treeStage,
            environment: environment,
            lastTreeUpdate: lastTreeUpdate
        )
    }

    private func firestoreData(from user: UserModel) -> [String: Any] {
        [
            "xp": user.xp,
            "level": user.level,
            "tasksCompleted": user.tasksCompleted,
            "treeLevel": user.treeLevel,
            "treeStage": user.treeStage.rawValue,
            "environment": user.environment.rawValue,
            "lastTreeUpdate": user.lastTreeUpdate.map(Timestamp.init(date:)) ?? NSNull()
        ]
    }
}
