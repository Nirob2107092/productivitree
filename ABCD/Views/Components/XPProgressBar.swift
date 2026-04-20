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
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(currentLevelXP)/\(xpPerLevel)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.Colors.surfaceAlt)

                    Capsule()
                        .fill(LinearGradient(
                            colors: [Theme.Colors.accent, Theme.Colors.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 10)
        }
    }
}
