//
//  HabitListView.swift
//  ABCD
//

import SwiftUI
import FirebaseAuth

struct HabitListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var habitService = HabitService()
    @StateObject private var viewModel: HabitViewModel

    init() {
        let service = HabitService()
        _habitService = StateObject(wrappedValue: service)
        _viewModel = StateObject(wrappedValue: HabitViewModel(habitService: service))
    }

    var body: some View {
        NavigationStack {
            Group {
                if habitService.habits.isEmpty {
                    EmptyStateView(
                        icon: "flame",
                        title: "No Habits Yet",
                        message: "Tap + to create your first habit and start building streaks!"
                    )
                } else {
                    List {
                        ForEach(habitService.habits) { habit in
                            HabitRowView(habit: habit, viewModel: viewModel)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { i in
                                viewModel.deleteHabit(habitService.habits[i])
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showAddHabit = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddHabit) {
                AddHabitView(viewModel: viewModel)
            }
            .onAppear {
                if let userId = authService.currentUser?.uid {
                    viewModel.startListening(userId: userId)
                }
            }
        }
    }
}

// MARK: - Habit Row

struct HabitRowView: View {
    let habit: HabitModel
    @ObservedObject var viewModel: HabitViewModel

    private var completedToday: Bool {
        viewModel.isCompletedToday(habit)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Toggle circle
                Button {
                    viewModel.toggleHabit(habit)
                } label: {
                    Image(systemName: completedToday ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(completedToday ? .orange : .gray)
                }
                .buttonStyle(.plain)

                // Habit title
                Text(habit.title)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                // Streak badge
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.subheadline)
                    Text("\(habit.currentStreak)")
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
            }

            // 14-day streak visualization
            StreakVisualization(
                completedDates: habit.completedDates,
                recentDates: viewModel.recentDateStrings(count: 14)
            )
            .padding(.leading, 36)

            // Best streak footnote
            if habit.bestStreak > 0 {
                Text("Best: \(habit.bestStreak) days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 36)
            }
        }
        .padding(.vertical, 6)
    }
}
