//
//  SessionDetailView.swift
//  ABCD
//

import SwiftUI

struct SessionDetailView: View {
    @EnvironmentObject var authService: AuthService
    @ObservedObject var viewModel: StudySessionViewModel
    let sessionId: String

    var body: some View {
        Group {
            if let session = currentSession {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header(session)

                        if !session.participants.isEmpty {
                            participantsSection(session)
                        } else {
                            EmptyStateView(
                                icon: "person.2",
                                title: "No Participants Yet",
                                message: "Share this session so others can join."
                            )
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

    private func actionButtons(_ session: StudySession) -> some View {
        let userId = authService.currentUser?.uid ?? ""
        let isCreator = viewModel.isCreator(session, userId: userId)
        let isParticipant = viewModel.isParticipant(session, userId: userId)

        return VStack(spacing: 12) {
            if isCreator {
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