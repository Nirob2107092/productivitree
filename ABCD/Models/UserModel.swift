//
//  UserModel.swift
//  ABCD
//

import Foundation

struct UserModel: Codable, Identifiable {
    var id: String              // Firebase Auth UID
    var email: String
    var displayName: String
    var xp: Int                 // Total XP earned
    var level: Int              // Current level (xp / 100)
    var tasksCompleted: Int
    var totalFocusMinutes: Int
    var createdAt: Date
}
