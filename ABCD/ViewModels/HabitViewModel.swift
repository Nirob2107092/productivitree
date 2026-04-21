//
//  HabitViewModel.swift
//  ABCD
//

import Foundation
import Combine

class HabitViewModel: ObservableObject {
    @Published var showAddHabit = false

    let habitService: HabitService

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    init(habitService: HabitService) {
        self.habitService = habitService
    }

    // MARK: - Start Listening

    func startListening(userId: String) {
        habitService.fetchHabits(userId: userId)
    }

    // MARK: - Add Habit

    func addHabit(title: String, userId: String) {
        let habit = HabitModel(
            id: UUID().uuidString,
            userId: userId,
            title: title,
            completedDates: [],
            xpAwardedDates: [],
            currentStreak: 0,
            bestStreak: 0,
            createdAt: Date()
        )
        habitService.createHabit(habit: habit)
    }

    // MARK: - Toggle Today

    func toggleHabit(_ habit: HabitModel, completionImageData: Data? = nil) {
        habitService.toggleTodayCompletion(habit: habit, completionImageData: completionImageData)
    }

    // MARK: - Delete

    func deleteHabit(_ habit: HabitModel) {
        habitService.deleteHabit(habitId: habit.id)
    }

    // MARK: - Helpers

    func isCompletedToday(_ habit: HabitModel) -> Bool {
        let today = Self.dateFormatter.string(from: Date())
        return habit.completedDates.contains(today)
    }

    /// Returns the last `count` calendar dates as "yyyy-MM-dd" strings (most recent last).
    func recentDateStrings(count: Int = 14) -> [String] {
        let calendar = Calendar(identifier: .gregorian)
        return (0..<count).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            return Self.dateFormatter.string(from: date)
        }
    }
}
