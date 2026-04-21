//
//  AnalyticsView.swift
//  ABCD
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    let focusSessions: [FocusSessionModel]
    let completedTasks: [TaskModel]
    let habits: [HabitModel]

    private static let calendar = Calendar(identifier: .gregorian)

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    private var last7Days: [Date] {
        let today = Self.calendar.startOfDay(for: Date())
        return (0..<7).compactMap { Self.calendar.date(byAdding: .day, value: -6 + $0, to: today) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                focusSection
                tasksSection
                xpSection
            }
            .padding()
        }
        .navigationTitle("Analytics")
    }

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Focus Minutes")
                .font(.headline)
            if weeklyFocusData.allSatisfy({ $0.value == 0 }) {
                EmptyStateView(message: "Complete focus sessions to see stats")
                    .frame(height: 120)
            } else {
                Chart(weeklyFocusData, id: \.label) { item in
                    BarMark(
                        x: .value("Day", item.label),
                        y: .value("Minutes", item.value)
                    )
                    .foregroundStyle(Color.blue.opacity(0.8))
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .frame(height: 200)
            }
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tasks Completed Per Day")
                .font(.headline)
            Chart(weeklyTaskData, id: \.label) { item in
                BarMark(
                    x: .value("Day", item.label),
                    y: .value("Tasks", item.value)
                )
                .foregroundStyle(Color.green.opacity(0.8))
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
    }

    private var xpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("XP Growth")
                .font(.headline)
            Chart(xpGrowthData, id: \.label) { item in
                LineMark(
                    x: .value("Day", item.label),
                    y: .value("XP", item.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.purple)

                AreaMark(
                    x: .value("Day", item.label),
                    y: .value("XP", item.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.15), Color.purple.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
    }

    private var weeklyFocusData: [(label: String, value: Int)] {
        let sessions = focusSessions.filter { session in
            let day = Self.calendar.startOfDay(for: session.completedAt)
            guard let first = last7Days.first, let last = last7Days.last else { return false }
            return day >= first && day <= last
        }

        return last7Days.map { day in
            let minutes = sessions
                .filter { Self.calendar.isDate($0.completedAt, inSameDayAs: day) }
                .reduce(0) { $0 + $1.durationMinutes }
            return (Self.dayFormatter.string(from: day), minutes)
        }
    }

    private var weeklyTaskData: [(label: String, value: Int)] {
        last7Days.map { day in
            let count = completedTasks.filter { task in
                guard task.isCompleted, let completedAt = task.completedAt else { return false }
                return Self.calendar.isDate(completedAt, inSameDayAs: day)
            }.count
            return (Self.dayFormatter.string(from: day), count)
        }
    }

    private var xpGrowthData: [(label: String, value: Int)] {
        var cumulative = 0

        return last7Days.map { day in
            let taskXp = completedTasks.reduce(0) { partial, task in
                guard task.isCompleted, let completedAt = task.completedAt,
                      Self.calendar.isDate(completedAt, inSameDayAs: day) else {
                    return partial
                }
                return partial + 10
            }

            let habitXp = habits.reduce(0) { partial, habit in
                let formatter = Self.isoDateFormatter
                let key = formatter.string(from: day)
                return habit.completedDates.contains(key) ? partial + 20 : partial
            }

            cumulative += taskXp + habitXp
            return (Self.dayFormatter.string(from: day), cumulative)
        }
    }

    private static var isoDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }
}

#Preview {
    NavigationStack {
        AnalyticsView(
            focusSessions: [
                FocusSessionModel(id: "f1", userId: "u1", durationMinutes: 45, breakMinutes: 10, mode: .deepWork, completedAt: Date()),
                FocusSessionModel(id: "f2", userId: "u1", durationMinutes: 25, breakMinutes: 5, mode: .learning, completedAt: Date().addingTimeInterval(-86400))
            ],
            completedTasks: [
                TaskModel(id: "t1", userId: "u1", title: "Task A", description: "", priority: .high, isCompleted: true, createdAt: Date(), deadline: Date().addingTimeInterval(86400), completedAt: Date())
            ],
            habits: [
                HabitModel(
                    id: "h1",
                    userId: "u1",
                    title: "Read",
                    completedDates: ["2026-04-20", "2026-04-21"],
                    xpAwardedDates: ["2026-04-20", "2026-04-21"],
                    currentStreak: 2,
                    bestStreak: 2,
                    createdAt: Date()
                )
            ]
        )
    }
}
