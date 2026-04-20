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
        let userRef = db.collection(Constants.Collections.users).document(userId)

        userRef.getDocument { snapshot, _ in
            guard let snapshot = snapshot, snapshot.exists,
                  let currentXP = snapshot.data()?["xp"] as? Int else {
                return
            }

            let currentLevel = snapshot.data()?["level"] as? Int ?? (currentXP / Constants.XP.xpPerLevel)
            let newXP = currentXP + amount
            let newLevel = newXP / Constants.XP.xpPerLevel

            userRef.updateData([
                "xp": newXP,
                "level": newLevel
            ]) { _ in
                if newLevel > currentLevel {
                    NotificationCenter.default.post(
                        name: .didLevelUp,
                        object: nil,
                        userInfo: [
                            "userId": userId,
                            "newLevel": newLevel,
                            "xp": newXP
                        ]
                    )
                }
            }
        }
    }

    // MARK: - Increment Tasks Completed

    func incrementTasksCompleted(userId: String) {
        let userRef = db.collection(Constants.Collections.users).document(userId)

        userRef.updateData([
            "tasksCompleted": FieldValue.increment(Int64(1))
        ])
    }
}
