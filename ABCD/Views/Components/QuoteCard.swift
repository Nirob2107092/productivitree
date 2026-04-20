//
//  QuoteCard.swift
//  ABCD
//

import SwiftUI

struct QuoteCard: View {
    let quote: Quote
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Daily Motivation", systemImage: "quote.bubble")
                    .font(.headline)
                Spacer()
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.Colors.accent)
            }

            Text("\"\(quote.content)\"")
                .font(.body)
                .foregroundColor(.primary)

            Text("- \(quote.author)")
                .font(.subheadline)
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
