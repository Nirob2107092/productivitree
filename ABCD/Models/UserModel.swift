//
//  UserModel.swift
//  ABCD
//

import Foundation

enum TreeStage: String, Codable, CaseIterable {
    case seed
    case sprout
    case sapling
    case tree
    case forest
}

enum EnvironmentType: String, Codable, CaseIterable {
    case normal
    case sunny
    case rainy
    case night
}

struct UserModel: Codable, Identifiable {
    var id: String              // Firebase Auth UID
    var email: String
    var displayName: String
    var xp: Int                 // Total XP earned
    var level: Int              // Current level (xp / 100)
    var tasksCompleted: Int
    var totalFocusMinutes: Int
    var createdAt: Date
    var treeLevel: Int
    var treeStage: TreeStage
    var environment: EnvironmentType
    var lastTreeUpdate: Date?

    init(
        id: String,
        email: String,
        displayName: String,
        xp: Int,
        level: Int,
        tasksCompleted: Int,
        totalFocusMinutes: Int,
        createdAt: Date,
        treeLevel: Int = 1,
        treeStage: TreeStage = .seed,
        environment: EnvironmentType = .normal,
        lastTreeUpdate: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.xp = xp
        self.level = level
        self.tasksCompleted = tasksCompleted
        self.totalFocusMinutes = totalFocusMinutes
        self.createdAt = createdAt
        self.treeLevel = treeLevel
        self.treeStage = treeStage
        self.environment = environment
        self.lastTreeUpdate = lastTreeUpdate
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case xp
        case level
        case tasksCompleted
        case totalFocusMinutes
        case createdAt
        case treeLevel
        case treeStage
        case environment
        case lastTreeUpdate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        xp = try container.decodeIfPresent(Int.self, forKey: .xp) ?? 0
        level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 0
        tasksCompleted = try container.decodeIfPresent(Int.self, forKey: .tasksCompleted) ?? 0
        totalFocusMinutes = try container.decodeIfPresent(Int.self, forKey: .totalFocusMinutes) ?? 0
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        treeLevel = try container.decodeIfPresent(Int.self, forKey: .treeLevel) ?? 1
        treeStage = try container.decodeIfPresent(TreeStage.self, forKey: .treeStage) ?? .seed
        environment = try container.decodeIfPresent(EnvironmentType.self, forKey: .environment) ?? .normal
        lastTreeUpdate = try container.decodeIfPresent(Date.self, forKey: .lastTreeUpdate)
    }
}
