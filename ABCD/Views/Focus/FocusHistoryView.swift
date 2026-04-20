//
//  FocusHistoryView.swift
//  ABCD
//

import SwiftUI

struct FocusHistoryView: View {
    @ObservedObject var focusService: FocusService

    var body: some View {
        VStack(spacing: 0) {
            summaryHeader

            if focusService.sessions.isEmpty {
                EmptyStateView(
                    icon: "timer",
                    title: "No Focus Sessions Yet",
                    message: "Complete a focus session to see your history here."
                )
            } else {
                List {
                    ForEach(focusService.sessions) { session in
                        SessionRow(session: session)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(spacing: 6) {
            Text("Total Focus Time")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            Text(formattedTotal)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(.purple)

            Text("\(focusService.sessions.count) session\(focusService.sessions.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.purple.opacity(0.08))
    }

    private var totalMinutes: Int {
        focusService.sessions.reduce(0) { $0 + $1.durationMinutes }
    }

    private var formattedTotal: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Session Row

private struct SessionRow: View {
    let session: FocusSessionModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.mode.iconName)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.mode.displayName)
                    .fontWeight(.medium)

                Text(session.completedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(session.durationMinutes) min")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var color: Color {
        switch session.mode {
        case .deepWork: return .purple
        case .learning: return .blue
        case .creating: return .orange
        }
    }
}
