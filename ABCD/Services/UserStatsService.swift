//
//  UserStatsService.swift
//  ABCD
//

import Foundation
import FirebaseFirestore

final class UserStatsService {
    private let db = Firestore.firestore()

    func fetchUserStats(userId: String) async throws -> UserStats {
        async let userSnapshot = db.collection(Constants.Collections.users)
            .document(userId)
            .getDocument()

        async let habitsSnapshot = db.collection(Constants.Collections.habits)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        let (userDoc, habitsDocs) = try await (userSnapshot, habitsSnapshot)

        let tasksCompleted = userDoc.data()?["tasksCompleted"] as? Int ?? 0
        let totalFocusMinutes = userDoc.data()?["totalFocusMinutes"] as? Int ?? 0
        let bestHabitStreak = habitsDocs.documents
            .compactMap { $0.data()["bestStreak"] as? Int }
            .max() ?? 0

        return UserStats(
            tasksCompleted: tasksCompleted,
            totalFocusMinutes: totalFocusMinutes,
            bestHabitStreak: bestHabitStreak
        )
    }
}
