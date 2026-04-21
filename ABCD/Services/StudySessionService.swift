//
//  StudySessionService.swift
//  ABCD
//

import Foundation
import Combine
import FirebaseFirestore

class StudySessionService: ObservableObject {
    @Published var sessions: [StudySession] = []
    @Published var errorMessage: String?
    @Published var participantDisplayNames: [String: String] = [:]

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    deinit {
        listener?.remove()
    }

    // MARK: - Fetch Sessions

    func fetchAllSessions() {
        listener?.remove()

        db.collection(Constants.Collections.studySessions)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }

                    let loadedSessions = (snapshot?.documents.compactMap { document in
                        self?.decodeSession(from: document)
                    } ?? [])
                    .sorted { $0.createdAt > $1.createdAt }

                    self?.sessions = loadedSessions
                    self?.fetchParticipantDisplayNames(from: loadedSessions)
                }
            }

        listener = db.collection(Constants.Collections.studySessions)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }

                    let loadedSessions = (snapshot?.documents.compactMap { document in
                        self?.decodeSession(from: document)
                    } ?? [])
                    .sorted { $0.createdAt > $1.createdAt }

                    self?.sessions = loadedSessions
                    self?.errorMessage = nil
                    self?.fetchParticipantDisplayNames(from: loadedSessions)
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Listen To Single Session

    func listenToSession(sessionId: String, onChange: @escaping (StudySession?) -> Void) -> ListenerRegistration {
        db.collection(Constants.Collections.studySessions)
            .document(sessionId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        onChange(nil)
                        return
                    }

                    guard let snapshot = snapshot, snapshot.exists else {
                        onChange(nil)
                        return
                    }

                    onChange(self?.decodeSession(from: snapshot))
                }
            }
    }

    // MARK: - Resolve Participant Display Names

    func displayName(for userId: String) -> String {
        participantDisplayNames[userId] ?? userId
    }

    private func fetchParticipantDisplayNames(from sessions: [StudySession]) {
        let userIds = Array(Set(sessions.flatMap { $0.participants }))

        guard !userIds.isEmpty else {
            participantDisplayNames = [:]
            return
        }

        participantDisplayNames = [:]

        for chunk in userIds.chunked(into: 10) {
            db.collection(Constants.Collections.users)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments { [weak self] snapshot, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.errorMessage = error.localizedDescription
                            return
                        }

                        snapshot?.documents.forEach { document in
                            let data = document.data()
                            let displayName = data["displayName"] as? String ?? document.documentID
                            self?.participantDisplayNames[document.documentID] = displayName
                        }
                    }
                }
        }
    }

    // MARK: - Create Session

    func createSession(session: StudySession) {
        db.collection(Constants.Collections.studySessions)
            .document(session.id)
            .setData(sessionData(from: session)) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Failed to create session: \(error.localizedDescription)"
                    }
                }
            }
    }

    // MARK: - Join Session

    func joinSession(sessionId: String, userId: String) {
        validateAndUpdate(sessionId: sessionId, userId: userId) { session in
            guard session.creatorId != userId else {
                return .failure(.message("You cannot join your own session."))
            }

            guard !session.participants.contains(userId) else {
                return .failure(.message("You are already in this session."))
            }

            return .success([
                "participants": FieldValue.arrayUnion([userId])
            ])
        }
    }

    // MARK: - Leave Session

    func leaveSession(sessionId: String, userId: String) {
        validateAndUpdate(sessionId: sessionId, userId: userId) { session in
            guard session.participants.contains(userId) else {
                return .failure(.message("You are not part of this session."))
            }

            var updates: [String: Any] = [
                "participants": FieldValue.arrayRemove([userId])
            ]

            if session.isActive {
                updates["activeParticipants"] = FieldValue.arrayRemove([userId])
                updates["leftParticipants"] = FieldValue.arrayUnion([userId])
            }

            return .success(updates)
        }
    }

    // MARK: - Focus Together Controls

    func startSession(sessionId: String, userId: String, duration: Int) {
        validateAndUpdate(sessionId: sessionId, userId: userId) { session in
            guard session.creatorId == userId else {
                return .failure(.message("Only the creator can start this session."))
            }

            guard !session.isActive else {
                return .failure(.message("Session is already active."))
            }

            let starterParticipants = Array(Set(session.participants + [session.creatorId]))

            return .success([
                "isActive": true,
                "startTime": Timestamp(date: Date()),
                "durationMinutes": max(duration, 1),
                "participants": starterParticipants,
                "activeParticipants": starterParticipants,
                "leftParticipants": [],
                "lastLeaderboard": []
            ])
        }
    }

    func joinActiveSession(sessionId: String, userId: String) {
        validateAndUpdate(sessionId: sessionId, userId: userId) { session in
            guard session.isActive else {
                return .failure(.message("Session has not started yet."))
            }

            return .success([
                "participants": FieldValue.arrayUnion([userId]),
                "activeParticipants": FieldValue.arrayUnion([userId]),
                "leftParticipants": FieldValue.arrayRemove([userId])
            ])
        }
    }

    func leaveActiveSession(sessionId: String, userId: String) {
        validateAndUpdate(sessionId: sessionId, userId: userId) { session in
            guard session.isActive else {
                return .failure(.message("Session is not active."))
            }

            guard session.activeParticipants.contains(userId) else {
                return .failure(.message("You are not active in this session."))
            }

            return .success([
                "activeParticipants": FieldValue.arrayRemove([userId]),
                "leftParticipants": FieldValue.arrayUnion([userId])
            ])
        }
    }

    func endSession(sessionId: String, userId: String) {
        validateAndUpdate(sessionId: sessionId, userId: userId) { session in
            guard session.creatorId == userId else {
                return .failure(.message("Only the creator can end this session."))
            }

            let winners = session.participants.filter { !session.leftParticipants.contains($0) }
            let leaderboard = winners + session.leftParticipants

            return .success([
                "isActive": false,
                "activeParticipants": [],
                "lastLeaderboard": leaderboard
            ])
        }
    }

    // MARK: - Delete Session

    func deleteSession(sessionId: String, userId: String) {
        db.collection(Constants.Collections.studySessions)
            .document(sessionId)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    guard let snapshot = snapshot,
                          let session = self.decodeSession(from: snapshot) else {
                        self.errorMessage = "Session not found."
                        return
                    }

                    guard session.creatorId == userId else {
                        self.errorMessage = "Only the creator can delete this session."
                        return
                    }

                    self.db.collection(Constants.Collections.studySessions)
                        .document(sessionId)
                        .delete { deleteError in
                            DispatchQueue.main.async {
                                if let deleteError = deleteError {
                                    self.errorMessage = "Failed to delete session: \(deleteError.localizedDescription)"
                                }
                            }
                        }
                }
            }
    }

    // MARK: - Shared Validation Helper

    private enum ValidationFailure: Error {
        case message(String)

        var description: String {
            switch self {
            case .message(let text): return text
            }
        }
    }

    private func validateAndUpdate(
        sessionId: String,
        userId: String,
        update: @escaping (StudySession) -> Result<[String: Any], ValidationFailure>
    ) {
        db.collection(Constants.Collections.studySessions)
            .document(sessionId)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    guard let snapshot = snapshot,
                          let session = self.decodeSession(from: snapshot) else {
                        self.errorMessage = "Session not found."
                        return
                    }

                    switch update(session) {
                    case .success(let data):
                        self.db.collection(Constants.Collections.studySessions)
                            .document(sessionId)
                            .updateData(data) { updateError in
                                DispatchQueue.main.async {
                                    if let updateError = updateError {
                                        self.errorMessage = "Failed to update session: \(updateError.localizedDescription)"
                                    }
                                }
                            }
                    case .failure(let failure):
                        self.errorMessage = failure.description
                    }
                }
            }
    }

    private func sessionData(from session: StudySession) -> [String: Any] {
        var data: [String: Any] = [
            "id": session.id,
            "title": session.title,
            "scheduledAt": Timestamp(date: session.scheduledAt),
            "category": session.category.rawValue,
            "creatorId": session.creatorId,
            "creatorName": session.creatorName,
            "participants": session.participants,
            "activeParticipants": session.activeParticipants,
            "isActive": session.isActive,
            "durationMinutes": session.durationMinutes,
            "leftParticipants": session.leftParticipants,
            "lastLeaderboard": session.lastLeaderboard,
            "createdAt": Timestamp(date: session.createdAt)
        ]

        if let startTime = session.startTime {
            data["startTime"] = Timestamp(date: startTime)
        } else {
            data["startTime"] = NSNull()
        }

        return data
    }

    private func decodeSession(from doc: QueryDocumentSnapshot) -> StudySession? {
        decodeSession(data: doc.data(), id: doc.documentID)
    }

    private func decodeSession(from snapshot: DocumentSnapshot) -> StudySession? {
        guard let data = snapshot.data() else { return nil }
        return decodeSession(data: data, id: snapshot.documentID)
    }

    private func decodeSession(data: [String: Any], id: String) -> StudySession? {
        guard let title = data["title"] as? String else {
            return nil
        }

        let creatorId = (data["creatorId"] as? String)
            ?? (data["userId"] as? String)
            ?? "unknown"
        let creatorName = (data["creatorName"] as? String)
            ?? (data["displayName"] as? String)
            ?? creatorId

        let categoryRaw = (data["category"] as? String)?.lowercased() ?? "study"
        let category = SessionCategory(rawValue: categoryRaw) ?? .study

        let createdAt = parseDate(data["createdAt"]) ?? Date.distantPast
        let scheduledAt = parseDate(data["scheduledAt"]) ?? createdAt
        let participants = data["participants"] as? [String] ?? []
        let activeParticipants = data["activeParticipants"] as? [String] ?? []
        let isActive = data["isActive"] as? Bool ?? false
        let startTime = parseDate(data["startTime"])
        let durationMinutes = data["durationMinutes"] as? Int ?? 25
        let leftParticipants = data["leftParticipants"] as? [String] ?? []
        let lastLeaderboard = data["lastLeaderboard"] as? [String] ?? []

        return StudySession(
            id: id,
            title: title,
            scheduledAt: scheduledAt,
            category: category,
            creatorId: creatorId,
            creatorName: creatorName,
            participants: participants,
            activeParticipants: activeParticipants,
            isActive: isActive,
            startTime: startTime,
            durationMinutes: durationMinutes,
            leftParticipants: leftParticipants,
            lastLeaderboard: lastLeaderboard,
            createdAt: createdAt
        )
    }

    private func parseDate(_ value: Any?) -> Date? {
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue()
        }
        if let date = value as? Date {
            return date
        }
        return nil
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var result: [[Element]] = []
        var index = 0
        while index < count {
            let endIndex = Swift.min(index + size, count)
            result.append(Array(self[index..<endIndex]))
            index += size
        }
        return result
    }
}