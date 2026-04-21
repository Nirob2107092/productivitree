//
//  XPProgressBar.swift
//  ABCD
//

import SwiftUI

struct XPProgressBar: View {
    let xp: Int
    let xpPerLevel: Int

    private var currentLevelXP: Int {
        xp % xpPerLevel
    }

    private var progress: Double {
        guard xpPerLevel > 0 else { return 0 }
        return Double(currentLevelXP) / Double(xpPerLevel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("XP Progress")
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)

                Spacer()

                Text("\(currentLevelXP)/\(xpPerLevel)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.Colors.surfaceAlt)

                    Capsule()
                        .fill(Theme.Gradients.accent)
                        .frame(width: proxy.size.width * progress)

                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 16, height: 16)
                        .shadow(color: Theme.Colors.accent.opacity(0.25), radius: 6, x: 0, y: 3)
                        .offset(x: max(0, (proxy.size.width * progress) - 16))
                }
            }
            .frame(height: 14)
        }
    }
}
