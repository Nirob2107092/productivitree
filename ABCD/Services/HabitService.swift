//
//  HabitService.swift
//  ABCD
//

import Foundation
import Combine
import FirebaseFirestore

class HabitService: ObservableObject {
    @Published var habits: [HabitModel] = []
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // Date formatter shared across all streak methods — UTC to avoid timezone boundary issues
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    deinit {
        listener?.remove()
    }

    // MARK: - Fetch Habits (Snapshot Listener)

    func fetchHabits(userId: String) {
        listener?.remove()

        listener = db.collection(Constants.Collections.habits)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    self?.habits = snapshot?.documents.compactMap { doc in
                        try? doc.data(as: HabitModel.self)
                    } ?? []
                }
            }
    }

    // MARK: - Create Habit

    func createHabit(habit: HabitModel) {
        do {
            try db.collection(Constants.Collections.habits)
                .document(habit.id)
                .setData(from: habit)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create habit: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Toggle Today's Completion

    func toggleTodayCompletion(habit: HabitModel) {
        let today = Self.dateFormatter.string(from: Date())
        var updatedHabit = habit

        if updatedHabit.completedDates.contains(today) {
            // Already completed today — un-complete it, no XP deduction
            updatedHabit.completedDates.removeAll { $0 == today }
        } else {
            // Not yet completed today — mark complete and award XP
            updatedHabit.completedDates.append(today)
            GamificationService.shared.addXP(userId: habit.userId, amount: Constants.XP.habitCompleted)
        }

        // Recalculate streaks after any change
        let newCurrentStreak = calculateCurrentStreak(completedDates: updatedHabit.completedDates)
        updatedHabit.currentStreak = newCurrentStreak
        updatedHabit.bestStreak = max(updatedHabit.bestStreak, newCurrentStreak)

        do {
            try db.collection(Constants.Collections.habits)
                .document(habit.id)
                .setData(from: updatedHabit, merge: true)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to update habit: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Delete Habit

    func deleteHabit(habitId: String) {
        db.collection(Constants.Collections.habits)
            .document(habitId)
            .delete { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Failed to delete habit: \(error.localizedDescription)"
                    }
                }
            }
    }

    // MARK: - Streak Calculation

    /// Walks backwards from today through completedDates counting consecutive days.
    /// Uses UTC dates to avoid timezone-related off-by-one errors.
    private func calculateCurrentStreak(completedDates: [String]) -> Int {
        guard !completedDates.isEmpty else { return 0 }

        let calendar = Calendar(identifier: .gregorian)
        var checkDate = Date()
        var streak = 0

        while true {
            let dateString = Self.dateFormatter.string(from: checkDate)
            if completedDates.contains(dateString) {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            } else {
                break
            }
        }

        return streak
    }
}
