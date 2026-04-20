//
//  TaskService.swift
//  ABCD
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseFirestoreSwift

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
                        try? doc.data(as: TaskModel.self)
                    } ?? []
                }
            }
    }

    // MARK: - Create Task

    func createTask(task: TaskModel) {
        do {
            try db.collection(Constants.Collections.tasks)
                .document(task.id)
                .setData(from: task)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to create task: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Update Task

    func updateTask(task: TaskModel) {
        do {
            try db.collection(Constants.Collections.tasks)
                .document(task.id)
                .setData(from: task, merge: true)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to update task: \(error.localizedDescription)"
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
        var updatedTask = task
        updatedTask.isCompleted = true
        updatedTask.completedAt = Date()

        do {
            try db.collection(Constants.Collections.tasks)
                .document(task.id)
                .setData(from: updatedTask, merge: true)

            // Award XP and increment stats
            GamificationService.shared.addXP(userId: task.userId, amount: Constants.XP.taskCompleted)
            GamificationService.shared.incrementTasksCompleted(userId: task.userId)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to complete task: \(error.localizedDescription)"
            }
        }
    }
}
