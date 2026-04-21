//
//  TreeView.swift
//  ABCD
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct TreeView: View {
    var stage: TreeStage
    var environment: EnvironmentType

    @State private var growthScale: CGFloat = 1.0
    @State private var sway = false
    @State private var sparklePhase = false
    @State private var rainOffset: CGFloat = -20

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(backgroundGradient)
                .overlay(alignment: .top) {
                    skyDecor
                }
                .overlay(alignment: .bottom) {
                    foregroundHills
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )

            VStack(spacing: 10) {
                HStack {
                    Label(stageLabel, systemImage: stageIcon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.96))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.14))
                        .clipShape(Capsule())

                    Spacer()

                    Label(environmentLabel, systemImage: environmentIcon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.12))
                        .clipShape(Capsule())
                }

                Spacer(minLength: 0)

                treeScene
                    .frame(height: 190)
                    .scaleEffect(growthScale)
                    .animation(.spring(response: 0.45, dampingFraction: 0.72), value: growthScale)

                Text(stageDescription)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.84))
                    .multilineTextAlignment(.center)
            }
            .padding(18)
        }
        .frame(height: 300)
        .onAppear {
            startAmbientAnimations()
        }
        .onChange(of: stage) { _, _ in
            animateGrowth()
        }
        .onTapGesture {
            animateGrowth(extraBounce: true)
            triggerHaptic()
        }
    }

    private var treeScene: some View {
        ZStack(alignment: .bottom) {
            ground

            if environment == .rainy {
                rainLayer
            }

            switch stage {
            case .seed:
                seedStage
            case .sprout:
                sproutStage
            case .sapling:
                saplingStage
            case .tree:
                treeStage
            case .forest:
                forestStage
            }
        }
    }

    private var ground: some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(Color.black.opacity(0.12))
                .frame(width: 190, height: 28)
                .blur(radius: 8)
                .offset(y: 8)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.24, green: 0.45, blue: 0.24),
                            Color(red: 0.43, green: 0.62, blue: 0.33)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 220, height: 52)
        }
    }

    private var foregroundHills: some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(Color.white.opacity(0.08))
                .frame(width: 270, height: 78)
                .offset(x: -100, y: 26)

            Ellipse()
                .fill(Color.black.opacity(0.08))
                .frame(width: 320, height: 90)
                .offset(x: 120, y: 30)
        }
    }

    private var skyDecor: some View {
        ZStack {
            switch environment {
            case .sunny:
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.yellow.opacity(0.95), Color.orange.opacity(0.2)],
                            center: .center,
                            startRadius: 8,
                            endRadius: 48
                        )
                    )
                    .frame(width: 86, height: 86)
                    .offset(x: 110, y: 14)
            case .night:
                starField
            case .rainy:
                rainCloud
            case .normal:
                cloudPair
            }
        }
        .padding(.top, 8)
    }

    private var cloudPair: some View {
        HStack {
            cloud(width: 70, opacity: 0.25)
            Spacer()
            cloud(width: 96, opacity: 0.22)
        }
        .padding(.horizontal, 24)
    }

    private func cloud(width: CGFloat, opacity: Double) -> some View {
        Capsule()
            .fill(Color.white.opacity(opacity))
            .frame(width: width, height: width * 0.32)
            .overlay(alignment: .leading) {
                Circle()
                    .fill(Color.white.opacity(opacity))
                    .frame(width: width * 0.34, height: width * 0.34)
                    .offset(x: width * 0.12, y: -8)
            }
            .overlay(alignment: .trailing) {
                Circle()
                    .fill(Color.white.opacity(opacity))
                    .frame(width: width * 0.4, height: width * 0.4)
                    .offset(x: -width * 0.12, y: -10)
            }
    }

    private var rainCloud: some View {
        VStack(spacing: 6) {
            cloud(width: 112, opacity: 0.30)

            HStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.45))
                        .frame(width: 3, height: 18)
                }
            }
            .offset(y: rainOffset)
        }
        .padding(.trailing, 120)
    }

    private var rainLayer: some View {
        HStack(spacing: 24) {
            ForEach(0..<6, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 2, height: 26)
                    .rotationEffect(.degrees(12))
                    .offset(y: rainOffset + CGFloat(index * 4))
            }
        }
        .offset(y: -10)
    }

    private var starField: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(sparklePhase ? 0.95 : 0.45))
                    .frame(width: index.isMultiple(of: 2) ? 4 : 3, height: index.isMultiple(of: 2) ? 4 : 3)
                    .offset(starOffset(for: index))
                    .animation(
                        .easeInOut(duration: 1.3).repeatForever(autoreverses: true).delay(Double(index) * 0.1),
                        value: sparklePhase
                    )
            }

            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: 26, height: 26)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 10)
                )
                .offset(x: 112, y: 18)
        }
    }

    private var seedStage: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.39, green: 0.23, blue: 0.13), Color(red: 0.28, green: 0.17, blue: 0.10)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 92, height: 34)
                .offset(y: 2)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.44, green: 0.23, blue: 0.12), Color(red: 0.31, green: 0.16, blue: 0.09)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 26, height: 26)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 5)
                .offset(y: -8)
        }
    }

    private var sproutStage: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(Color(red: 0.35, green: 0.26, blue: 0.18))
                .frame(width: 10, height: 70)

            HStack(spacing: 0) {
                LeafShape()
                    .fill(leafGradient)
                    .frame(width: 42, height: 28)
                    .rotationEffect(.degrees(sway ? -12 : -4))
                    .offset(x: 8, y: -54)

                LeafShape()
                    .fill(leafGradient)
                    .frame(width: 42, height: 28)
                    .scaleEffect(x: -1, y: 1)
                    .rotationEffect(.degrees(sway ? 12 : 4))
                    .offset(x: -8, y: -54)
            }
        }
    }

    private var saplingStage: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(trunkGradient)
                .frame(width: 18, height: 96)

            VStack(spacing: -14) {
                canopy(width: 66, height: 48, color: Color(red: 0.38, green: 0.71, blue: 0.34))
                canopy(width: 84, height: 56, color: Color(red: 0.31, green: 0.63, blue: 0.29))
            }
            .offset(y: -34)
        }
    }

    private var treeStage: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(trunkGradient)
                .frame(width: 24, height: 124)

            VStack(spacing: -18) {
                canopy(width: 88, height: 64, color: Color(red: 0.46, green: 0.77, blue: 0.34))
                canopy(width: 120, height: 82, color: Color(red: 0.34, green: 0.67, blue: 0.28))
                canopy(width: 98, height: 66, color: Color(red: 0.27, green: 0.56, blue: 0.24))
            }
            .offset(y: -44)
        }
        .overlay(alignment: .top) {
            HStack(spacing: 20) {
                Circle().fill(Color.white.opacity(0.18)).frame(width: 10, height: 10)
                Circle().fill(Color.yellow.opacity(0.28)).frame(width: 8, height: 8)
                Circle().fill(Color.white.opacity(0.18)).frame(width: 10, height: 10)
            }
            .offset(y: 8)
        }
    }

    private var forestStage: some View {
        HStack(alignment: .bottom, spacing: 12) {
            miniTree(scale: 0.72, offsetY: 8, tint: Color(red: 0.23, green: 0.52, blue: 0.24))
            miniTree(scale: 1.0, offsetY: 0, tint: Color(red: 0.30, green: 0.65, blue: 0.29))
            miniTree(scale: 0.84, offsetY: 10, tint: Color(red: 0.40, green: 0.73, blue: 0.35))
        }
    }

    private func miniTree(scale: CGFloat, offsetY: CGFloat, tint: Color) -> some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(trunkGradient)
                .frame(width: 20 * scale, height: 90 * scale)

            VStack(spacing: -16 * scale) {
                canopy(width: 72 * scale, height: 52 * scale, color: tint.opacity(0.92))
                canopy(width: 92 * scale, height: 66 * scale, color: tint)
            }
            .offset(y: -32 * scale)
        }
        .offset(y: offsetY)
    }

    private func canopy(width: CGFloat, height: CGFloat, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.95), color.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: height)

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: width * 0.34, height: width * 0.34)
                .offset(x: -width * 0.14, y: -height * 0.16)
        }
        .rotationEffect(.degrees(sway ? 2 : -2))
        .shadow(color: color.opacity(0.25), radius: 10, x: 0, y: 8)
    }

    private var trunkGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.43, green: 0.28, blue: 0.18), Color(red: 0.29, green: 0.18, blue: 0.11)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var leafGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.56, green: 0.86, blue: 0.39), Color(red: 0.24, green: 0.63, blue: 0.27)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var backgroundGradient: LinearGradient {
        switch environment {
        case .normal:
            return LinearGradient(
                colors: [
                    Color(red: 0.63, green: 0.84, blue: 0.95),
                    Color(red: 0.48, green: 0.76, blue: 0.85),
                    Color(red: 0.78, green: 0.90, blue: 0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sunny:
            return LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.86, blue: 0.52),
                    Color(red: 0.96, green: 0.71, blue: 0.39),
                    Color(red: 0.79, green: 0.89, blue: 0.63)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .rainy:
            return LinearGradient(
                colors: [
                    Color(red: 0.34, green: 0.46, blue: 0.60),
                    Color(red: 0.43, green: 0.59, blue: 0.70),
                    Color(red: 0.63, green: 0.75, blue: 0.74)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .night:
            return LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.13, blue: 0.24),
                    Color(red: 0.17, green: 0.24, blue: 0.39),
                    Color(red: 0.26, green: 0.37, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var stageLabel: String {
        switch stage {
        case .seed: return "Seed"
        case .sprout: return "Sprout"
        case .sapling: return "Sapling"
        case .tree: return "Tree"
        case .forest: return "Forest"
        }
    }

    private var stageDescription: String {
        switch stage {
        case .seed: return "Your productivity journey has started. Small actions are preparing growth."
        case .sprout: return "Consistency is showing. The first signs of momentum are visible."
        case .sapling: return "Your routine is strengthening into a stable and healthy habit system."
        case .tree: return "You are in a strong growth phase with visible progress across modules."
        case .forest: return "Sustained effort has created a thriving productivity ecosystem."
        }
    }

    private var environmentLabel: String {
        switch environment {
        case .normal: return "Balanced Day"
        case .sunny: return "High Energy"
        case .rainy: return "Reflective Mode"
        case .night: return "Late Focus"
        }
    }

    private var stageIcon: String {
        switch stage {
        case .seed: return "circle.fill"
        case .sprout: return "leaf.fill"
        case .sapling: return "tree.fill"
        case .tree: return "tree.circle.fill"
        case .forest: return "leaf.circle.fill"
        }
    }

    private var environmentIcon: String {
        switch environment {
        case .normal: return "cloud.sun.fill"
        case .sunny: return "sun.max.fill"
        case .rainy: return "cloud.rain.fill"
        case .night: return "moon.stars.fill"
        }
    }

    private func starOffset(for index: Int) -> CGSize {
        let positions: [CGSize] = [
            CGSize(width: -118, height: 14),
            CGSize(width: -70, height: 34),
            CGSize(width: -20, height: 18),
            CGSize(width: 36, height: 42),
            CGSize(width: 78, height: 26),
            CGSize(width: 22, height: 4),
            CGSize(width: -92, height: 58),
            CGSize(width: 64, height: 64)
        ]
        return positions[index]
    }

    private func startAmbientAnimations() {
        sway = true
        sparklePhase = true
        rainOffset = 16
    }

    private func animateGrowth(extraBounce: Bool = false) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) {
            growthScale = extraBounce ? 1.10 : 1.08
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82).delay(0.14)) {
            growthScale = 1.0
        }
        triggerHaptic()
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

private struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        return path
    }
}
