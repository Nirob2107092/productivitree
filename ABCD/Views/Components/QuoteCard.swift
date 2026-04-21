//
//  QuoteCard.swift
//  ABCD
//

import SwiftUI

struct QuoteCard: View {
    let quote: Quote
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Daily Motivation", systemImage: "quote.bubble")
                    .font(.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                        .padding(10)
                        .background(Theme.Colors.accent.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.Colors.accent)
            }

            Text("\"\(quote.content)\"")
                .font(.body.weight(.medium))
                .foregroundColor(Theme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("- \(quote.author)")
                .font(.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(fill: LinearGradient(
            colors: [
                Color.white.opacity(0.96),
                Color(red: 0.95, green: 0.97, blue: 0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
    }
}
