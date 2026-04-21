//
//  TreeService.swift
//  ABCD
//

import Foundation

struct TreeService {
    private let streak: Int
    private let activityAt: Date?

    init(streak: Int = 0, activityAt: Date? = nil) {
        self.streak = streak
        self.activityAt = activityAt
    }

    func updateTreeState(for user: UserModel) -> UserModel {
        var updatedUser = user

        let stage = stageForXP(user.xp)
        updatedUser.treeStage = stage
        updatedUser.treeLevel = stage.numericLevel

        let effectiveActivity = activityAt ?? Date()
        updatedUser.environment = environmentForState(
            streak: streak,
            previousActivityAt: user.lastTreeUpdate,
            currentActivityAt: effectiveActivity
        )
        updatedUser.lastTreeUpdate = effectiveActivity

        return updatedUser
    }

    private func stageForXP(_ xp: Int) -> TreeStage {
        switch xp {
        case ..<100:
            return .seed
        case ..<300:
            return .sprout
        case ..<600:
            return .sapling
        case ..<1000:
            return .tree
        default:
            return .forest
        }
    }

    private func environmentForState(
        streak: Int,
        previousActivityAt: Date?,
        currentActivityAt: Date
    ) -> EnvironmentType {
        if streak >= 7 {
            return .sunny
        }

        if let previousActivityAt, isInactiveForTwoDaysOrMore(since: previousActivityAt, now: currentActivityAt) {
            return .rainy
        }

        let hour = Calendar.current.component(.hour, from: currentActivityAt)
        if hour >= 22 {
            return .night
        }

        return .normal
    }

    private func isInactiveForTwoDaysOrMore(since lastActivity: Date, now: Date) -> Bool {
        let dayDelta = Calendar.current.dateComponents([.day], from: lastActivity, to: now).day ?? 0
        return dayDelta >= 2
    }
}

private extension TreeStage {
    var numericLevel: Int {
        switch self {
        case .seed:
            return 1
        case .sprout:
            return 2
        case .sapling:
            return 3
        case .tree:
            return 4
        case .forest:
            return 5
        }
    }
}
