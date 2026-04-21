//
//  EmptyStateView.swift
//  ABCD
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    init(icon: String, title: String, message: String) {
        self.icon = icon
        self.title = title
        self.message = message
    }

    init(message: String) {
        self.icon = "chart.bar"
        self.title = "No Data Yet"
        self.message = message
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.accent.opacity(0.10))
                    .frame(width: 84, height: 84)

                Image(systemName: icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(Theme.Colors.accent)
            }

            Text(title)
                .font(.headline)
                .foregroundColor(Theme.Colors.textPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appCard(fill: Theme.Colors.surfaceStrong, padding: 24)
    }
}
