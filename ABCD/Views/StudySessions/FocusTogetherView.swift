//
//  FocusTogetherView.swift
//  ABCD
//

import SwiftUI

struct FocusTogetherView: View {
    @EnvironmentObject var authService: AuthService
    @ObservedObject var viewModel: StudySessionViewModel
    let session: StudySession

    @State private var previousParticipantCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Focus Together")
                .font(.headline)

            Text(session.title)
                .font(.title3)
                .fontWeight(.semibold)

            Text(formattedTime(viewModel.timeRemaining))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()

            HStack(spacing: 12) {
                Label("\(session.activeParticipants.count) active", systemImage: "person.2.fill")
                Label("\(Int(viewModel.groupProgress)) group points", systemImage: "leaf.fill")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            ProgressView(value: progressValue)
                .tint(.green)

            if !session.leftParticipants.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Left During Session")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(session.leftParticipants.map { viewModel.displayName(for: $0) }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }

            if let userId = authService.currentUser?.uid {
                if viewModel.isActiveParticipant(session, userId: userId) {
                    Button {
                        viewModel.leaveActiveSession(session, userId: userId)
                    } label: {
                        Text("Leave Focus")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.15))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                } else {
                    Button {
                        viewModel.joinActiveSession(session, userId: userId)
                    } label: {
                        Text("Rejoin Focus")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.08))
        .cornerRadius(16)
        .onAppear {
            previousParticipantCount = session.activeParticipants.count
        }
        .onChange(of: session.activeParticipants.count) { _, newValue in
            if newValue != previousParticipantCount {
                previousParticipantCount = newValue
                triggerHaptic()
            }
        }
    }

    private var progressValue: Double {
        guard session.durationMinutes > 0 else { return 0 }
        let total = Double(session.durationMinutes * 60)
        let elapsed = max(0, total - Double(viewModel.timeRemaining))
        return min(1, elapsed / total)
    }

    private func formattedTime(_ seconds: Int) -> String {
        let safe = max(0, seconds)
        let minutes = safe / 60
        let remainingSeconds = safe % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
