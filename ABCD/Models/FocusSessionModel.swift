//
//  FocusSessionModel.swift
//  ABCD
//

import Foundation

struct FocusSessionModel: Codable, Identifiable {
    var id: String
    var userId: String
    var durationMinutes: Int
    var mode: FocusMode
    var completedAt: Date
}

enum FocusMode: String, Codable, CaseIterable {
    case deepWork
    case learning
    case creating

    var displayName: String {
        switch self {
        case .deepWork: return "Deep Work"
        case .learning: return "Learning"
        case .creating: return "Creating"
        }
    }

    var iconName: String {
        switch self {
        case .deepWork: return "brain.head.profile"
        case .learning: return "book.fill"
        case .creating: return "paintbrush.fill"
        }
    }

    var defaultMinutes: Int {
        switch self {
        case .deepWork: return 50
        case .learning: return 25
        case .creating: return 15
        }
    }
}
