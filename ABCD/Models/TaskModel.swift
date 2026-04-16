//
//  TaskModel.swift
//  ABCD
//

import Foundation

struct TaskModel: Codable, Identifiable {
    var id: String
    var userId: String
    var title: String
    var description: String
    var priority: Priority
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
}

enum Priority: String, Codable, CaseIterable {
    case high, medium, low

    var displayName: String {
        rawValue.capitalized
    }

    var colorName: String {
        switch self {
        case .high: return "red"
        case .medium: return "orange"
        case .low: return "blue"
        }
    }
}
