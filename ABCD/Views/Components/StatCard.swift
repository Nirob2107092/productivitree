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
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(tint)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Colors.stroke, lineWidth: 1)
        )
        .cornerRadius(14)
    }
}
