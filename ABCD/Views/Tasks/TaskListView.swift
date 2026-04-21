//
//  TaskListView.swift
//  ABCD
//

import SwiftUI
import FirebaseAuth

struct TaskListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var taskService = TaskService()
    @StateObject private var viewModel: TaskViewModel

    init() {
        let service = TaskService()
        _taskService = StateObject(wrappedValue: service)
        _viewModel = StateObject(wrappedValue: TaskViewModel(taskService: service))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter picker
                Picker("Filter", selection: $viewModel.selectedFilter) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Task list or empty state
                if viewModel.filteredTasks.isEmpty {
                    EmptyStateView(
                        icon: emptyStateIcon,
                        title: emptyStateTitle,
                        message: emptyStateMessage
                    )
                } else {
                    List {
                        ForEach(viewModel.filteredTasks) { task in
                            TaskRowView(task: task)
                                .swipeActions(edge: .leading) {
                                    if !task.isCompleted && !viewModel.isOverdue(task) {
                                        Button {
                                            viewModel.completeTask(task)
                                        } label: {
                                            Label("Complete", systemImage: "checkmark.circle.fill")
                                        }
                                        .tint(.green)
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.deleteTask(task)
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddTask) {
                AddTaskView(viewModel: viewModel)
            }
            .alert("Tasks", isPresented: taskErrorBinding) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(taskService.errorMessage ?? "")
            }
            .onAppear {
                if let userId = authService.currentUser?.uid {
                    viewModel.startListening(userId: userId)
                }
            }
        }
    }

    // MARK: - Empty State Helpers

    private var emptyStateIcon: String {
        switch viewModel.selectedFilter {
        case .all: return "checkmark.circle"
        case .today: return "calendar"
        case .completed: return "trophy"
        case .highPriority: return "exclamationmark.triangle"
        case .unfinished: return "clock.badge.exclamationmark"
        }
    }

    private var emptyStateTitle: String {
        switch viewModel.selectedFilter {
        case .all: return "No Tasks Yet"
        case .today: return "No Tasks Today"
        case .completed: return "No Completed Tasks"
        case .highPriority: return "No High Priority Tasks"
        case .unfinished: return "No Unfinished Tasks"
        }
    }

    private var emptyStateMessage: String {
        switch viewModel.selectedFilter {
        case .all: return "Tap + to add your first task and start earning XP!"
        case .today: return "You're all caught up for today."
        case .completed: return "Complete tasks to see them here."
        case .highPriority: return "No urgent tasks right now."
        case .unfinished: return "Tasks that miss their deadline will appear here."
        }
    }

    private var taskErrorBinding: Binding<Bool> {
        Binding(
            get: { taskService.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    taskService.errorMessage = nil
                }
            }
        )
    }
}

// MARK: - Task Row

struct TaskRowView: View {
    let task: TaskModel

    var body: some View {
        HStack(spacing: 12) {
            // Completion indicator
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .gray)
                .font(.title3)

            // Task info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted, color: .gray)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)

                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if let deadline = task.deadline {
                    Text(deadlineText(deadline))
                        .font(.caption2)
                        .foregroundColor(isOverdue ? .red : .secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(task.priority.displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.15))
                    .foregroundColor(priorityColor)
                    .cornerRadius(6)

                if isOverdue {
                    Text("Overdue")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var isOverdue: Bool {
        guard !task.isCompleted, let deadline = task.deadline else { return false }
        return Date() > deadline
    }

    private var priorityColor: Color {
        switch task.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }

    private func deadlineText(_ deadline: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Due \(formatter.string(from: deadline))"
    }
}
