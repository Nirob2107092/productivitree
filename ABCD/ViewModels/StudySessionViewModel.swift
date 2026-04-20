//
//  StudySessionViewModel.swift
//  ABCD
//

import Foundation
import Combine

class StudySessionViewModel: ObservableObject {
    @Published var showCreateSession = false

    let studySessionService: StudySessionService

    init(studySessionService: StudySessionService) {
        self.studySessionService = studySessionService
    }

    var sessions: [StudySession] {
        studySessionService.sessions
    }

    var errorMessage: String? {
        studySessionService.errorMessage
    }

    func startListening() {
        studySessionService.fetchAllSessions()
    }

    func stopListening() {
        studySessionService.stopListening()
    }

    func displayName(for userId: String) -> String {
        studySessionService.displayName(for: userId)
    }

    func createSession(title: String, scheduledAt: Date, category: SessionCategory, creatorId: String, creatorName: String) {
        let session = StudySession(
            id: UUID().uuidString,
            title: title,
            scheduledAt: scheduledAt,
            category: category,
            creatorId: creatorId,
            creatorName: creatorName,
            participants: [],
            createdAt: Date()
        )
        studySessionService.createSession(session: session)
    }

    func joinSession(_ session: StudySession, userId: String) {
        studySessionService.joinSession(sessionId: session.id, userId: userId)
    }

    func leaveSession(_ session: StudySession, userId: String) {
        studySessionService.leaveSession(sessionId: session.id, userId: userId)
    }

    func deleteSession(_ session: StudySession, userId: String) {
        studySessionService.deleteSession(sessionId: session.id, userId: userId)
    }

    func session(withId id: String) -> StudySession? {
        sessions.first { $0.id == id }
    }

    func isCreator(_ session: StudySession, userId: String) -> Bool {
        session.creatorId == userId
    }

    func isParticipant(_ session: StudySession, userId: String) -> Bool {
        session.participants.contains(userId)
    }
}