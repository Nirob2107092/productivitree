//
//  GamificationService.swift
//  ABCD
//

import Foundation
import FirebaseFirestore

class GamificationService {
    static let shared = GamificationService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Add XP

    func addXP(userId: String, amount: Int) {
        let userRef = db.collection(Constants.Collections.users).document(userId)

        userRef.getDocument { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists,
                  let currentXP = snapshot.data()?["xp"] as? Int else {
                return
            }

            let newXP = currentXP + amount
            let newLevel = newXP / Constants.XP.xpPerLevel

            userRef.updateData([
                "xp": newXP,
                "level": newLevel
            ])
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
