//
//  FocusService.swift
//  ABCD
//

import Foundation
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
                        try? doc.data(as: FocusSessionModel.self)
                    } ?? []
                }
            }
    }

    // MARK: - Save Session

    func saveSession(session: FocusSessionModel) {
        do {
            try db.collection(Constants.Collections.focusSessions)
                .document(session.id)
                .setData(from: session)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to save session: \(error.localizedDescription)"
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
}
