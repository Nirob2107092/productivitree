//
//  Constants.swift
//  ABCD
//

import Foundation

struct Constants {
    // MARK: - Firestore Collection Names
    struct Collections {
        static let users = "users"
        static let tasks = "tasks"
        static let habits = "habits"
        static let focusSessions = "focus_sessions"
        static let studySessions = "study_sessions"
    }

    // MARK: - XP Values
    struct XP {
        static let taskCompleted = 10
        static let habitCompleted = 20
        static let xpPerLevel = 100
    }
}
