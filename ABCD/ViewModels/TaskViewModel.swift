//
//  TaskViewModel.swift
//  ABCD
//

import Foundation
import Combine

enum TaskFilter: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case completed = "Completed"
    case highPriority = "High"
}

class TaskViewModel: ObservableObject {
    @Published var selectedFilter: TaskFilter = .all
    @Published var showAddTask = false

    let taskService: TaskService

    private var cancellables = Set<AnyCancellable>()

    init(taskService: TaskService) {
        self.taskService = taskService
    }

    // MARK: - Filtered Tasks

    var filteredTasks: [TaskModel] {
        switch selectedFilter {
        case .all:
            return taskService.tasks.filter { !$0.isCompleted }
        case .today:
            return taskService.tasks.filter { task in
                !task.isCompleted && Calendar.current.isDateInToday(task.createdAt)
            }
        case .completed:
            return taskService.tasks.filter { $0.isCompleted }
        case .highPriority:
            return taskService.tasks.filter { !$0.isCompleted && $0.priority == .high }
        }
    }

    // MARK: - Actions

    func startListening(userId: String) {
        taskService.fetchTasks(userId: userId)
    }

    func addTask(title: String, description: String, priority: Priority, userId: String) {
        let task = TaskModel(
            id: UUID().uuidString,
            userId: userId,
            title: title,
            description: description,
            priority: priority,
            isCompleted: false,
            createdAt: Date(),
            completedAt: nil
        )
        taskService.createTask(task: task)
    }

    func completeTask(_ task: TaskModel) {
        taskService.completeTask(task: task)
    }

    func deleteTask(_ task: TaskModel) {
        taskService.deleteTask(taskId: task.id)
    }
}
