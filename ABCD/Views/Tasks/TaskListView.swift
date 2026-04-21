//
//  TaskListView.swift
//  ABCD
//

import SwiftUI
import FirebaseAuth
import PhotosUI
import UIKit

struct TaskListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var taskService = TaskService()
    @StateObject private var viewModel: TaskViewModel
    @State private var taskForPhotoCompletion: TaskModel?
    @State private var taskImagePreviewItem: RemoteImagePreviewItem?

    init() {
        let service = TaskService()
        _taskService = StateObject(wrappedValue: service)
        _viewModel = StateObject(wrappedValue: TaskViewModel(taskService: service))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Stay on top of your day")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Theme.Colors.textPrimary)

                            Text("\(viewModel.filteredTasks.count) tasks in \(viewModel.selectedFilter.rawValue.lowercased())")
                                .font(.subheadline)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }

                        Spacer()

                        ZStack {
                            Circle()
                                .fill(Theme.Colors.accent.opacity(0.12))
                                .frame(width: 46, height: 46)

                            Image(systemName: "checklist.checked")
                                .font(.headline)
                                .foregroundStyle(Theme.Colors.accent)
                        }
                    }

                    Picker("Filter", selection: $viewModel.selectedFilter) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .appCard(fill: Theme.Colors.surfaceStrong)

                if viewModel.filteredTasks.isEmpty {
                    EmptyStateView(
                        icon: emptyStateIcon,
                        title: emptyStateTitle,
                        message: emptyStateMessage
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.filteredTasks) { task in
                            TaskRowView(task: task) {
                                if let completionImageURL = task.completionImageURL {
                                    taskImagePreviewItem = RemoteImagePreviewItem(
                                        title: task.title,
                                        urlString: completionImageURL
                                    )
                                }
                            }
                            .swipeActions(edge: .leading) {
                                if !task.isCompleted && !viewModel.isOverdue(task) {
                                    Button {
                                        viewModel.completeTask(task)
                                    } label: {
                                        Label("Complete", systemImage: "checkmark.circle.fill")
                                    }
                                    .tint(.green)

                                    Button {
                                        taskForPhotoCompletion = task
                                    } label: {
                                        Label("Photo", systemImage: "photo.badge.checkmark")
                                    }
                                    .tint(.blue)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteTask(task)
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 7, leading: 0, bottom: 7, trailing: 0))
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .padding(.horizontal)
            .padding(.top, 14)
            .background(Theme.Gradients.appBackground.ignoresSafeArea())
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(Theme.Colors.accent)
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
            .sheet(item: $taskForPhotoCompletion) { task in
                CompletionPhotoSheet(
                    title: "Complete Task",
                    subtitle: task.title,
                    confirmTitle: "Complete Task"
                ) { imageData in
                    viewModel.completeTask(task, completionImageData: imageData)
                }
            }
            .sheet(item: $taskImagePreviewItem) { item in
                RemoteImagePreviewSheet(item: item)
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
    let onPreviewImage: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((task.isCompleted ? Theme.Colors.success : Theme.Colors.surfaceAlt).opacity(0.20))
                    .frame(width: 38, height: 38)

                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? Theme.Colors.success : Theme.Colors.textSecondary)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted, color: .gray)
                    .foregroundColor(task.isCompleted ? Theme.Colors.textSecondary : Theme.Colors.textPrimary)

                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }

                if let deadline = task.deadline {
                    Text(deadlineText(deadline))
                        .font(.caption2)
                        .foregroundColor(isOverdue ? .red : Theme.Colors.textSecondary)
                }

                if task.isCompleted, task.completionImageURL != nil {
                    Button {
                        onPreviewImage()
                    } label: {
                        Label("Photo attached", systemImage: "photo")
                            .font(.caption2)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .buttonStyle(.plain)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .appCard(fill: Theme.Colors.surfaceStrong, padding: 0)
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

struct CompletionPhotoSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let subtitle: String
    let confirmTitle: String
    let onConfirm: (Data?) -> Void

    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var previewImage: Image?

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 180)

                    if let previewImage {
                        previewImage
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("Optional proof image")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    onConfirm(imageData)
                    dismiss()
                } label: {
                    Text(confirmTitle)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button("Complete Without Photo") {
                    onConfirm(nil)
                    dismiss()
                }
                .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Add Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else {
                    imageData = nil
                    previewImage = nil
                    return
                }

                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            imageData = data
                            if let uiImage = UIImage(data: data) {
                                previewImage = Image(uiImage: uiImage)
                            } else {
                                previewImage = nil
                            }
                        }
                    }
                }
            }
        }
    }
}
