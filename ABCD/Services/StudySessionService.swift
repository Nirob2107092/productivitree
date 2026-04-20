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

        listener = db.collection(Constants.Collections.studySessions)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }

                    let loadedSessions = snapshot?.documents.compactMap { document in
                        try? document.data(as: StudySession.self)
                    } ?? []

                    self?.sessions = loadedSessions
                    self?.fetchParticipantDisplayNames(from: loadedSessions)
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
        do {
            try db.collection(Constants.Collections.studySessions)
                .document(session.id)
                .setData(from: session)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create session: \(error.localizedDescription)"
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

            return .success([
                "participants": FieldValue.arrayRemove([userId])
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
                          let session = try? snapshot.data(as: StudySession.self) else {
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
                          let session = try? snapshot.data(as: StudySession.self) else {
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