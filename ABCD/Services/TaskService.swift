//
//  TaskService.swift
//  ABCD
//

import Foundation
import Combine
import FirebaseFirestore

class TaskService: ObservableObject {
    @Published var tasks: [TaskModel] = []
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    deinit {
        listener?.remove()
    }

    // MARK: - Fetch Tasks (Snapshot Listener)

    func fetchTasks(userId: String) {
        listener?.remove()

        listener = db.collection(Constants.Collections.tasks)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }

                    self?.tasks = snapshot?.documents.compactMap { doc in
                        self?.decodeTask(from: doc)
                    } ?? []
                }
            }
    }

    // MARK: - Fetch Completed Tasks (One-Shot)

    func fetchCompletedTasks(userId: String) async throws -> [TaskModel] {
        do {
            let snapshot = try await db.collection(Constants.Collections.tasks)
                .whereField("userId", isEqualTo: userId)
                .whereField("isCompleted", isEqualTo: true)
                .order(by: "completedAt", descending: true)
                .getDocuments()

            return snapshot.documents.compactMap { document in
                try? document.data(as: TaskModel.self)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch completed tasks: \(error.localizedDescription)"
            }
            throw error
        }
    }

    // MARK: - Create Task

    func createTask(task: TaskModel) {
        db.collection(Constants.Collections.tasks)
            .document(task.id)
            .setData(taskData(from: task)) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Failed to create task: \(error.localizedDescription)"
                    }
                }
            }
    }

    // MARK: - Update Task

    func updateTask(task: TaskModel) {
        db.collection(Constants.Collections.tasks)
            .document(task.id)
            .setData(taskData(from: task), merge: true) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Failed to update task: \(error.localizedDescription)"
                    }
                }
            }
    }

    // MARK: - Delete Task

    func deleteTask(taskId: String) {
        db.collection(Constants.Collections.tasks)
            .document(taskId)
            .delete { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Failed to delete task: \(error.localizedDescription)"
                    }
                }
            }
    }

    // MARK: - Complete Task

    func completeTask(task: TaskModel) {
        guard !task.isCompleted else { return }
        if let deadline = task.deadline, Date() > deadline {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "This task is past its deadline and can no longer be completed."
            }
            return
        }

        var updatedTask = task
        updatedTask.isCompleted = true
        updatedTask.completedAt = Date()

        db.collection(Constants.Collections.tasks)
            .document(task.id)
            .setData(taskData(from: updatedTask), merge: true) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Failed to complete task: \(error.localizedDescription)"
                    }
                    return
                }

                // Single gamification write path for XP + stats + tree update.
                GamificationService.shared.applyTaskCompletion(
                    userId: task.userId,
                    xpAmount: Constants.XP.taskCompleted
                )
            }
    }

    private func taskData(from task: TaskModel) -> [String: Any] {
        var data: [String: Any] = [
            "id": task.id,
            "userId": task.userId,
            "title": task.title,
            "description": task.description,
            "priority": task.priority.rawValue,
            "isCompleted": task.isCompleted,
            "createdAt": Timestamp(date: task.createdAt)
        ]

        if let deadline = task.deadline {
            data["deadline"] = Timestamp(date: deadline)
        }

        if let completedAt = task.completedAt {
            data["completedAt"] = Timestamp(date: completedAt)
        } else {
            data["completedAt"] = NSNull()
        }

        return data
    }

    private func decodeTask(from doc: QueryDocumentSnapshot) -> TaskModel? {
        let data = doc.data()
        guard
            let userId = data["userId"] as? String,
            let title = data["title"] as? String,
            let description = data["description"] as? String,
            let priorityRaw = data["priority"] as? String,
            let priority = Priority(rawValue: priorityRaw),
            let isCompleted = data["isCompleted"] as? Bool,
            let createdAtTimestamp = data["createdAt"] as? Timestamp
        else {
            return nil
        }

        let completedAt = (data["completedAt"] as? Timestamp)?.dateValue()
        let deadline = (data["deadline"] as? Timestamp)?.dateValue()

        return TaskModel(
            id: doc.documentID,
            userId: userId,
            title: title,
            description: description,
            priority: priority,
            isCompleted: isCompleted,
            createdAt: createdAtTimestamp.dateValue(),
            deadline: deadline,
            completedAt: completedAt
        )
    }
}
