//
//  StudySession.swift
//  ABCD
//

import Foundation
import SwiftUI

struct StudySession: Codable, Identifiable {
    var id: String
    var title: String
    var scheduledAt: Date
    var category: SessionCategory
    var creatorId: String
    var creatorName: String
    var participants: [String]
    var activeParticipants: [String]
    var isActive: Bool
    var startTime: Date?
    var durationMinutes: Int
    var leftParticipants: [String]
    var lastLeaderboard: [String]
    var createdAt: Date

    init(
        id: String,
        title: String,
        scheduledAt: Date,
        category: SessionCategory,
        creatorId: String,
        creatorName: String,
        participants: [String],
        activeParticipants: [String] = [],
        isActive: Bool = false,
        startTime: Date? = nil,
        durationMinutes: Int = 25,
        leftParticipants: [String] = [],
        lastLeaderboard: [String] = [],
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.scheduledAt = scheduledAt
        self.category = category
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.participants = participants
        self.activeParticipants = activeParticipants
        self.isActive = isActive
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.leftParticipants = leftParticipants
        self.lastLeaderboard = lastLeaderboard
        self.createdAt = createdAt
    }
}

enum SessionCategory: String, Codable, CaseIterable {
    case study
    case work
    case coding

    var displayName: String {
        rawValue.capitalized
    }

    var iconName: String {
        switch self {
        case .study: return "book.fill"
        case .work: return "briefcase.fill"
        case .coding: return "chevron.left.forwardslash.chevron.right"
        }
    }

    var tintColor: Color {
        switch self {
        case .study: return .blue
        case .work: return .green
        case .coding: return .purple
        }
    }
}