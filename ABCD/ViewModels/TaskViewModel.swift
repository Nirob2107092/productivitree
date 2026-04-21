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

    var activeTasks: [TaskModel] {
        filteredIncompleteTasks.filter { !isOverdue($0) }
    }

    var unfinishedTasks: [TaskModel] {
        filteredIncompleteTasks.filter { isOverdue($0) }
    }

    var completedTasks: [TaskModel] {
        guard selectedFilter == .completed else { return [] }
        return taskService.tasks.filter { $0.isCompleted }
    }

    // MARK: - Actions

    func startListening(userId: String) {
        taskService.fetchTasks(userId: userId)
    }

    func addTask(title: String, description: String, priority: Priority, deadline: Date, userId: String) {
        let task = TaskModel(
            id: UUID().uuidString,
            userId: userId,
            title: title,
            description: description,
            priority: priority,
            isCompleted: false,
            createdAt: Date(),
            deadline: deadline,
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

    func isOverdue(_ task: TaskModel) -> Bool {
        guard !task.isCompleted, let deadline = task.deadline else { return false }
        return Date() > deadline
    }

    func matchesSelectedFilter(_ task: TaskModel) -> Bool {
        switch selectedFilter {
        case .all:
            return true
        case .today:
            return Calendar.current.isDateInToday(task.createdAt)
        case .completed:
            return task.isCompleted
        case .highPriority:
            return task.priority == .high
        }
    }

    private var filteredIncompleteTasks: [TaskModel] {
        taskService.tasks.filter { task in
            matchesSelectedFilter(task) && !task.isCompleted
        }
    }
}
