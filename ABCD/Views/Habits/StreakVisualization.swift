//
//  StreakVisualization.swift
//  ABCD
//

import SwiftUI

/// Horizontal row of small day-circles for the last 14 days.
/// Filled orange = completed, hollow gray = missed.
struct StreakVisualization: View {
    let completedDates: [String]
    let recentDates: [String]   // 14 "yyyy-MM-dd" strings, oldest → newest

    var body: some View {
        HStack(spacing: 4) {
            ForEach(recentDates, id: \.self) { dateString in
                let completed = completedDates.contains(dateString)
                Circle()
                    .fill(completed ? Color.orange : Color.gray.opacity(0.2))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(completed ? Color.orange : Color.gray.opacity(0.4), lineWidth: 1)
                    )
            }
        }
    }
}
