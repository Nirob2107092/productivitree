//
//  Theme.swift
//  ABCD
//

import SwiftUI

enum Theme {
    enum Colors {
        static let background = Color(red: 0.95, green: 0.97, blue: 0.94)
        static let backgroundSecondary = Color(red: 0.89, green: 0.94, blue: 0.91)
        static let surface = Color.white.opacity(0.78)
        static let surfaceStrong = Color.white.opacity(0.92)
        static let surfaceAlt = Color(red: 0.89, green: 0.92, blue: 0.89)
        static let stroke = Color.black.opacity(0.08)
        static let accent = Color(red: 0.15, green: 0.50, blue: 0.31)
        static let accentSecondary = Color(red: 0.20, green: 0.58, blue: 0.78)
        static let accentWarm = Color(red: 0.90, green: 0.61, blue: 0.27)
        static let warning = Color(red: 0.88, green: 0.46, blue: 0.20)
        static let success = Color(red: 0.23, green: 0.63, blue: 0.42)
        static let textPrimary = Color(red: 0.13, green: 0.18, blue: 0.16)
        static let textSecondary = Color(red: 0.39, green: 0.45, blue: 0.42)
    }

    enum Gradients {
        static let appBackground = LinearGradient(
            colors: [
                Colors.background,
                Colors.backgroundSecondary,
                Color(red: 0.96, green: 0.93, blue: 0.88)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let hero = LinearGradient(
            colors: [
                Color(red: 0.19, green: 0.42, blue: 0.27),
                Color(red: 0.29, green: 0.58, blue: 0.37),
                Color(red: 0.64, green: 0.78, blue: 0.55)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let accent = LinearGradient(
            colors: [Colors.accent, Colors.accentSecondary],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let warmAccent = LinearGradient(
            colors: [Colors.accentWarm, Color(red: 0.96, green: 0.79, blue: 0.39)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Layout {
        static let cardRadius: CGFloat = 24
        static let cardShadow = Color.black.opacity(0.08)
    }
}

struct AppCardModifier: ViewModifier {
    var padding: CGFloat = 18
    var fill: AnyShapeStyle = AnyShapeStyle(Theme.Colors.surface)

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(fill)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.cardRadius, style: .continuous)
                    .stroke(Theme.Colors.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardRadius, style: .continuous))
            .shadow(color: Theme.Layout.cardShadow, radius: 18, x: 0, y: 10)
    }
}

struct AppChipModifier: ViewModifier {
    var tint: Color

    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }
}

extension View {
    func appCard(padding: CGFloat = 18) -> some View {
        modifier(AppCardModifier(padding: padding))
    }

    func appCard(fill: some ShapeStyle, padding: CGFloat = 18) -> some View {
        modifier(AppCardModifier(padding: padding, fill: AnyShapeStyle(fill)))
    }

    func appChip(tint: Color) -> some View {
        modifier(AppChipModifier(tint: tint))
    }
}
