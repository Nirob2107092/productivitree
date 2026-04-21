//
//  HabitModel.swift
//  ABCD
//

import Foundation

struct HabitModel: Codable, Identifiable {
    var id: String
    var userId: String
    var title: String
    var completedDates: [String]  // Format: "yyyy-MM-dd" in UTC, e.g. ["2026-04-01", "2026-04-02"]
    var xpAwardedDates: [String] = []
    var completionImageURLs: [String: String] = [:]
    var currentStreak: Int
    var bestStreak: Int
    var createdAt: Date
}
