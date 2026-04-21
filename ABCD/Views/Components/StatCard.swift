//
//  StatCard.swift
//  ABCD
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let iconName: String
    let tint: Color

    init(title: String, value: String, iconName: String, tint: Color) {
        self.title = title
        self.value = value
        self.iconName = iconName
        self.tint = tint
    }

    init(icon: String, title: String, value: String, color: Color) {
        self.title = title
        self.value = value
        self.iconName = icon
        self.tint = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.14))
                        .frame(width: 42, height: 42)

                    Image(systemName: iconName)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(tint)
                }

                Spacer()
            }

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(Theme.Colors.textPrimary)

            Text(title)
                .font(.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(fill: Theme.Colors.surfaceStrong)
    }
}
