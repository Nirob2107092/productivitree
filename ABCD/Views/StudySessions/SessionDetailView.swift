//
//  SessionDetailView.swift
//  ABCD
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SessionDetailView: View {
    @EnvironmentObject var authService: AuthService
    @ObservedObject var viewModel: StudySessionViewModel
    let sessionId: String
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedDuration: Int = 25

    var body: some View {
        Group {
            if let session = currentSession {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header(session)

                        switch sessionState(session) {
                        case .notStarted, .waiting:
                            if !session.participants.isEmpty {
                                participantsSection(session)
                            } else {
                                EmptyStateView(
                                    icon: "person.2",
                                    title: "No Participants Yet",
                                    message: "Share this session so others can join."
                                )
                            }
                        case .active:
                            FocusTogetherView(viewModel: viewModel, session: session)
                        case .finished:
                            resultsSection(session)
                        }

                        actionButtons(session)
                    }
                    .padding()
                }
                .navigationTitle("Session Detail")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                EmptyStateView(
                    icon: "questionmark.circle",
                    title: "Session Not Found",
                    message: "This session may have been deleted."
                )
            }
        }
        .overlay(alignment: .top) {
            if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage)
                    .padding(.top, 8)
                    .padding(.horizontal)
            }
        }
        .onAppear {
            if let userId = authService.currentUser?.uid {
                viewModel.observeSession(sessionId: sessionId, userId: userId)
            }
        }
        .onChange(of: authService.currentUser?.uid) { _, userId in
            guard let userId else { return }
            viewModel.observeSession(sessionId: sessionId, userId: userId)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.recalculateTimer()
            }
        }
        .onDisappear {
            viewModel.stopSessionObservation()
        }
    }

    private var currentSession: StudySession? {
        viewModel.session(withId: sessionId)
    }

    private func header(_ session: StudySession) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(session.creatorName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                CategoryBadge(category: session.category)
            }

            HStack(spacing: 14) {
                Label(session.scheduledAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                Label("\(session.participants.count) participant\(session.participants.count == 1 ? "" : "s")", systemImage: "person.2")
                if session.isActive {
                    Label("Live", systemImage: "dot.radiowaves.left.and.right")
                        .foregroundColor(.green)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }

    private func participantsSection(_ session: StudySession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants")
                .font(.headline)

            ForEach(session.participants, id: \.self) { participant in
                HStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.secondary)
                    Text(viewModel.displayName(for: participant))
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.06))
        .cornerRadius(16)
    }

    private func resultsSection(_ session: StudySession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Focusers")
                .font(.headline)

            let ranking = session.lastLeaderboard.isEmpty
                ? session.participants.filter { !session.leftParticipants.contains($0) } + session.leftParticipants
                : session.lastLeaderboard

            ForEach(Array(ranking.enumerated()), id: \.offset) { index, userId in
                HStack {
                    Text("\(index + 1).")
                        .fontWeight(.semibold)
                    Text(viewModel.displayName(for: userId))
                    Spacer()
                    if session.leftParticipants.contains(userId) {
                        Text("Left Early")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.06))
        .cornerRadius(16)
    }

    private func actionButtons(_ session: StudySession) -> some View {
        let userId = authService.currentUser?.uid ?? ""
        let isCreator = viewModel.isCreator(session, userId: userId)
        let isParticipant = viewModel.isParticipant(session, userId: userId)

        return VStack(spacing: 12) {
            if isCreator {
                if !session.isActive {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Session Duration")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Picker("Duration", selection: $selectedDuration) {
                            Text("25 min").tag(25)
                            Text("50 min").tag(50)
                            Text("90 min").tag(90)
                        }
                        .pickerStyle(.segmented)

                        Button {
                            viewModel.startSession(session, userId: userId, duration: selectedDuration)
                        } label: {
                            Text("Start Session")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.08))
                    .cornerRadius(14)
                } else {
                    Button {
                        viewModel.endSession(session, userId: userId)
                    } label: {
                        Text("End Session")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.16))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                    }
                }

                Button(role: .destructive) {
                    viewModel.deleteSession(session, userId: userId)
                } label: {
                    Text("Delete Session")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
            } else {
    // Non-creator controls:
    // - While active: controls are shown inside FocusTogetherView (avoid duplicate Leave Focus button here).
    // - While inactive: show Join/Leave Session.
    if !session.isActive {
        Button {
            if isParticipant {
                viewModel.leaveSession(session, userId: userId)
            } else {
                viewModel.joinSession(session, userId: userId)
            }
        } label: {
            Text(isParticipant ? "Leave Session" : "Join Session")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isParticipant ? Color.gray.opacity(0.15) : Color.green)
                .foregroundColor(isParticipant ? .primary : .white)
                .cornerRadius(12)
        }
        .disabled(userId.isEmpty)
    }
}
        }
    }

    private enum DetailSessionState {
        case notStarted
        case waiting
        case active
        case finished
    }

    private func sessionState(_ session: StudySession) -> DetailSessionState {
        if session.isActive {
            return .active
        }

        if session.startTime != nil && !session.lastLeaderboard.isEmpty {
            return .finished
        }

        if session.participants.isEmpty {
            return .notStarted
        }

        return .waiting
    }

    private func buttonTitle(session: StudySession, isParticipant: Bool, userId: String) -> String {
        if session.isActive {
            return viewModel.isActiveParticipant(session, userId: userId) ? "Leave Focus" : "Join Focus"
        }
        return isParticipant ? "Leave Session" : "Join Session"
    }

    private func buttonBackground(session: StudySession, isParticipant: Bool, userId: String) -> Color {
        if session.isActive {
            return viewModel.isActiveParticipant(session, userId: userId) ? Color.gray.opacity(0.15) : Color.green
        }
        return isParticipant ? Color.gray.opacity(0.15) : Color.green
    }

    private func buttonForeground(session: StudySession, isParticipant: Bool, userId: String) -> Color {
        if session.isActive {
            return viewModel.isActiveParticipant(session, userId: userId) ? .primary : .white
        }
        return isParticipant ? .primary : .white
    }
}

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(12)
    }
}