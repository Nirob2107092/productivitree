//
//  UserStats.swift
//  ABCD
//

import Foundation

struct UserStats {
    let tasksCompleted: Int
    let totalFocusMinutes: Int
    let bestHabitStreak: Int

    static let empty = UserStats(tasksCompleted: 0, totalFocusMinutes: 0, bestHabitStreak: 0)
}
