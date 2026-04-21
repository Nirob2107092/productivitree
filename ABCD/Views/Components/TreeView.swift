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
    @State private var leafPulse = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(backgroundGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )

            VStack(spacing: 8) {
                Text(stageLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))

                treeVisual
                    .scaleEffect(growthScale)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: growthScale)

                Text(environmentLabel)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
        }
        .frame(height: 180)
        .onChange(of: stage) { _, _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                growthScale = 1.15
            }
            withAnimation(.easeInOut(duration: 0.25).delay(0.25)) {
                growthScale = 1.0
            }
            triggerHaptic()
        }
        .onTapGesture {
            leafPulse.toggle()
            withAnimation(.easeInOut(duration: 0.25)) {
                growthScale = 1.08
            }
            withAnimation(.easeInOut(duration: 0.2).delay(0.2)) {
                growthScale = 1.0
            }
            triggerHaptic()
        }
    }

    private var treeVisual: some View {
        Group {
            switch stage {
            case .seed:
                Circle()
                    .fill(Color.brown.opacity(0.9))
                    .frame(width: 18, height: 18)
            case .sprout:
                Image(systemName: "leaf.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color.green)
                    .scaleEffect(leafPulse ? 1.07 : 1.0)
            case .sapling:
                Image(systemName: "tree.fill")
                    .font(.system(size: 44, weight: .regular))
                    .foregroundStyle(.green)
            case .tree:
                Image(systemName: "tree.circle.fill")
                    .font(.system(size: 54, weight: .regular))
                    .foregroundStyle(.green)
            case .forest:
                HStack(spacing: 8) {
                    Image(systemName: "tree.fill")
                    Image(systemName: "tree.fill")
                    Image(systemName: "tree.fill")
                }
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.green)
            }
        }
    }

    private var stageLabel: String {
        switch stage {
        case .seed:
            return "Seed"
        case .sprout:
            return "Sprout"
        case .sapling:
            return "Sapling"
        case .tree:
            return "Tree"
        case .forest:
            return "Forest"
        }
    }

    private var environmentLabel: String {
        switch environment {
        case .normal:
            return "Normal"
        case .sunny:
            return "Sunny"
        case .rainy:
            return "Rainy"
        case .night:
            return "Night"
        }
    }

    private var backgroundGradient: LinearGradient {
        switch environment {
        case .normal:
            return LinearGradient(colors: [Color.green.opacity(0.35), Color.blue.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .sunny:
            return LinearGradient(colors: [Color.yellow.opacity(0.65), Color.orange.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .rainy:
            return LinearGradient(colors: [Color.gray.opacity(0.6), Color.blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .night:
            return LinearGradient(colors: [Color.indigo.opacity(0.8), Color.black.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
