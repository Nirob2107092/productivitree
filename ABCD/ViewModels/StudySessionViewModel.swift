//
//  StudySessionViewModel.swift
//  ABCD
//

import Foundation
import Combine
import FirebaseFirestore

class StudySessionViewModel: ObservableObject {
    @Published var showCreateSession = false
    @Published var currentSession: StudySession?
    @Published var timeRemaining: Int = 0
    @Published var groupProgress: Double = 0
    @Published var leaderboard: [String] = []

    let studySessionService: StudySessionService

    private var sessionListener: ListenerRegistration?
    private var timerCancellable: AnyCancellable?
    private var endRequested = false
    private var observerUserId: String?

    init(studySessionService: StudySessionService) {
        self.studySessionService = studySessionService
    }

    deinit {
        sessionListener?.remove()
        timerCancellable?.cancel()
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
        stopSessionObservation()
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

    // MARK: - Focus Together

    func observeSession(sessionId: String, userId: String) {
        observerUserId = userId
        sessionListener?.remove()
        sessionListener = studySessionService.listenToSession(sessionId: sessionId) { [weak self] session in
            guard let self else { return }
            self.currentSession = session
            self.refreshDerivedState(for: session)
        }
    }

    func stopSessionObservation() {
        sessionListener?.remove()
        sessionListener = nil
        timerCancellable?.cancel()
        timerCancellable = nil
        currentSession = nil
        timeRemaining = 0
        groupProgress = 0
        leaderboard = []
        endRequested = false
        observerUserId = nil
    }

    func startSession(_ session: StudySession, userId: String, duration: Int) {
        studySessionService.startSession(sessionId: session.id, userId: userId, duration: duration)
    }

    func joinActiveSession(_ session: StudySession, userId: String) {
        studySessionService.joinActiveSession(sessionId: session.id, userId: userId)
    }

    func leaveActiveSession(_ session: StudySession, userId: String) {
        studySessionService.leaveActiveSession(sessionId: session.id, userId: userId)
    }

    func endSession(_ session: StudySession, userId: String) {
        studySessionService.endSession(sessionId: session.id, userId: userId)
    }

    func recalculateTimer() {
        refreshDerivedState(for: currentSession)
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
        if let currentSession, currentSession.id == id {
            return currentSession
        }
        return sessions.first { $0.id == id }
    }

    func isCreator(_ session: StudySession, userId: String) -> Bool {
        session.creatorId == userId
    }

    func isParticipant(_ session: StudySession, userId: String) -> Bool {
        session.participants.contains(userId)
    }

    func isActiveParticipant(_ session: StudySession, userId: String) -> Bool {
        session.activeParticipants.contains(userId)
    }

    private func refreshDerivedState(for session: StudySession?) {
        guard let session else {
            timerCancellable?.cancel()
            timerCancellable = nil
            timeRemaining = 0
            groupProgress = 0
            leaderboard = []
            endRequested = false
            return
        }

        leaderboard = session.lastLeaderboard

        guard session.isActive, let startTime = session.startTime else {
            timerCancellable?.cancel()
            timerCancellable = nil
            timeRemaining = 0
            groupProgress = 0
            endRequested = false
            return
        }

        updateTimer(for: session, startTime: startTime)

        if timerCancellable == nil {
            timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self else { return }
                    guard let activeSession = self.currentSession,
                          activeSession.isActive,
                          let activeStart = activeSession.startTime else {
                        self.timerCancellable?.cancel()
                        self.timerCancellable = nil
                        return
                    }
                    self.updateTimer(for: activeSession, startTime: activeStart)
                }
        }
    }

    private func updateTimer(for session: StudySession, startTime: Date) {
        let durationSeconds = max(session.durationMinutes, 1) * 60
        let elapsed = max(0, Int(Date().timeIntervalSince(startTime)))
        timeRemaining = max(0, durationSeconds - elapsed)

        groupProgress = Double(session.activeParticipants.count * elapsed)

        if timeRemaining == 0,
           !endRequested,
           let creatorSession = currentSession,
           observerUserId == creatorSession.creatorId {
            endRequested = true
            studySessionService.endSession(sessionId: creatorSession.id, userId: creatorSession.creatorId)
        }
    }
}