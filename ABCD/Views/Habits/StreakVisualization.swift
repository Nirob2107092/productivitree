//
//  StreakVisualization.swift
//  ABCD
//

import SwiftUI

/// Compatibility wrapper kept to avoid breaking older references.
/// Habit heatmap is now the default visualization.
struct StreakVisualization: View {
    let habit: HabitModel

    var body: some View {
        HabitHeatmapView(habit: habit)
    }
}
