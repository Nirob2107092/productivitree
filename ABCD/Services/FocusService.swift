//
//  FocusService.swift
//  ABCD
//

import Foundation
import Combine
import FirebaseFirestore

class FocusService: ObservableObject {
    @Published var sessions: [FocusSessionModel] = []
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    deinit {
        listener?.remove()
    }

    // MARK: - Fetch Session History

    func fetchSessionHistory(userId: String) {
        listener?.remove()

        listener = db.collection(Constants.Collections.focusSessions)
            .whereField("userId", isEqualTo: userId)
            .order(by: "completedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    self?.sessions = snapshot?.documents.compactMap { doc in
                        self?.decodeSession(from: doc)
                    } ?? []
                }
            }
    }

    // MARK: - Save Session

    func saveSession(session: FocusSessionModel) {
        db.collection(Constants.Collections.focusSessions)
            .document(session.id)
            .setData(sessionData(from: session)) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Failed to save session: \(error.localizedDescription)"
                    }
                }
            }
    }

    // MARK: - Update Total Focus Time

    func updateTotalFocusTime(userId: String, minutes: Int) {
        db.collection(Constants.Collections.users)
            .document(userId)
            .updateData([
                "totalFocusMinutes": FieldValue.increment(Int64(minutes))
            ])
    }

    private func sessionData(from session: FocusSessionModel) -> [String: Any] {
        [
            "id": session.id,
            "userId": session.userId,
            "durationMinutes": session.durationMinutes,
            "mode": session.mode.rawValue,
            "completedAt": Timestamp(date: session.completedAt)
        ]
    }

    private func decodeSession(from doc: QueryDocumentSnapshot) -> FocusSessionModel? {
        let data = doc.data()
        guard
            let userId = data["userId"] as? String,
            let durationMinutes = data["durationMinutes"] as? Int,
            let modeRaw = data["mode"] as? String,
            let mode = FocusMode(rawValue: modeRaw),
            let completedAtTimestamp = data["completedAt"] as? Timestamp
        else {
            return nil
        }

        return FocusSessionModel(
            id: doc.documentID,
            userId: userId,
            durationMinutes: durationMinutes,
            mode: mode,
            completedAt: completedAtTimestamp.dateValue()
        )
    }
}
