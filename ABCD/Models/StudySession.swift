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
    var createdAt: Date
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