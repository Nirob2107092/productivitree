//
//  HabitHeatmapView.swift
//  ABCD
//

import SwiftUI

struct HabitHeatmapView: View {
    let habit: HabitModel

    private static let calendar = Calendar(identifier: .gregorian)

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    private var startDate: Date {
        let today = Date()
        let weekday = Self.calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        let thisMonday = Self.calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        return Self.calendar.date(byAdding: .weekOfYear, value: -11, to: thisMonday) ?? thisMonday
    }

    private var heatmapDates: [Date] {
        (0..<84).compactMap { Self.calendar.date(byAdding: .day, value: $0, to: startDate) }
    }

    private var completedSet: Set<String> {
        Set(habit.completedDates)
    }

    private var todayDateOnly: Date {
        Self.calendar.startOfDay(for: Date())
    }

    private var weekColumns: [[Date]] {
        stride(from: 0, to: heatmapDates.count, by: 7).map { start in
            Array(heatmapDates[start..<min(start + 7, heatmapDates.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            monthLabels
            weeksGrid
            legend
        }
    }

    private var monthLabels: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(Array(weekColumns.enumerated()), id: \.offset) { index, week in
                Text(monthLabelForWeek(index: index, week: week))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 12, alignment: .leading)
            }
        }
    }

    private var weeksGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(12), spacing: 4), count: 12), spacing: 4) {
            ForEach(0..<7, id: \.self) { row in
                ForEach(0..<12, id: \.self) { col in
                    let date = weekColumns[col][row]
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color(for: date))
                        .frame(width: 12, height: 12)
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 6) {
            Text("Less")
                .font(.caption2)
                .foregroundColor(.secondary)

            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.systemGray5))
                .frame(width: 10, height: 10)

            RoundedRectangle(cornerRadius: 3)
                .fill(Color("AccentGreen").opacity(0.45))
                .frame(width: 10, height: 10)

            RoundedRectangle(cornerRadius: 3)
                .fill(Color("AccentGreen").opacity(0.85))
                .frame(width: 10, height: 10)

            Text("More")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func color(for date: Date) -> Color {
        let dateOnly = Self.calendar.startOfDay(for: date)
        if dateOnly > todayDateOnly {
            return Color(.systemGray6).opacity(0.3)
        }

        let key = Self.dateFormatter.string(from: dateOnly)
        if completedSet.contains(key) {
            return Color("AccentGreen").opacity(0.85)
        }
        return Color(.systemGray5)
    }

    private func monthLabelForWeek(index: Int, week: [Date]) -> String {
        guard let first = week.first else { return "" }
        if index == 0 {
            return Self.monthFormatter.string(from: first)
        }

        let previousWeekLast = weekColumns[index - 1].last ?? first
        let previousMonth = Self.calendar.component(.month, from: previousWeekLast)
        let currentMonth = Self.calendar.component(.month, from: first)
        return previousMonth != currentMonth ? Self.monthFormatter.string(from: first) : ""
    }
}

#Preview {
    HabitHeatmapView(
        habit: HabitModel(
            id: "h1",
            userId: "u1",
            title: "Read 30 minutes",
            completedDates: ["2026-04-01", "2026-04-03", "2026-04-04", "2026-04-10", "2026-04-11"],
            xpAwardedDates: ["2026-04-01", "2026-04-03", "2026-04-04", "2026-04-10", "2026-04-11"],
            currentStreak: 2,
            bestStreak: 5,
            createdAt: Date()
        )
    )
    .padding()
}
