//
//  StudySessionListView.swift
//  ABCD
//

import SwiftUI

struct StudySessionListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel: StudySessionViewModel

    init() {
        let service = StudySessionService()
        _viewModel = StateObject(wrappedValue: StudySessionViewModel(studySessionService: service))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.sessions.isEmpty {
                    EmptyStateView(
                        icon: "person.2.fill",
                        title: "No Study Sessions Yet",
                        message: "Create a session and let others join for accountability."
                    )
                } else {
                    List {
                        ForEach(viewModel.sessions) { session in
                            NavigationLink {
                                SessionDetailView(viewModel: viewModel, sessionId: session.id)
                            } label: {
                                StudySessionRow(session: session)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Study Sessions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showCreateSession = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCreateSession) {
                CreateSessionView(viewModel: viewModel)
            }
            .task(id: authService.currentUser?.uid) {
                guard authService.currentUser?.uid != nil else { return }
                viewModel.startListening()
            }
            .onDisappear {
                viewModel.stopListening()
            }
            .overlay(alignment: .top) {
                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage)
                        .padding(.top, 8)
                        .padding(.horizontal)
                }
            }
        }
    }
}

private struct StudySessionRow: View {
    let session: StudySession

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(session.creatorName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                CategoryBadge(category: session.category)
            }

            HStack(spacing: 14) {
                Label(formattedDate(session.scheduledAt), systemImage: "calendar")
                Label("\(session.participants.count) participant\(session.participants.count == 1 ? "" : "s")", systemImage: "person.2")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}

struct CategoryBadge: View {
    let category: SessionCategory

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.iconName)
            Text(category.displayName)
        }
        .font(.caption2)
        .fontWeight(.semibold)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(category.tintColor.opacity(0.15))
        .foregroundColor(category.tintColor)
        .cornerRadius(8)
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