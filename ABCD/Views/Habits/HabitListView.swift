//
//  HabitListView.swift
//  ABCD
//

import SwiftUI
import FirebaseAuth
import PhotosUI

struct HabitListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var habitService = HabitService()
    @StateObject private var viewModel: HabitViewModel
    @State private var habitForPhotoCompletion: HabitModel?
    @State private var habitImagePreviewItem: RemoteImagePreviewItem?

    init() {
        let service = HabitService()
        _habitService = StateObject(wrappedValue: service)
        _viewModel = StateObject(wrappedValue: HabitViewModel(habitService: service))
    }

    var body: some View {
        NavigationStack {
            Group {
                if habitService.habits.isEmpty {
                    EmptyStateView(
                        icon: "flame",
                        title: "No Habits Yet",
                        message: "Tap + to create your first habit and start building streaks!"
                    )
                } else {
                    List {
                        ForEach(habitService.habits) { habit in
                            HabitRowView(habit: habit, viewModel: viewModel) {
                                habitForPhotoCompletion = habit
                            } onPreviewImage: {
                                if let urlString = habit.completionImageURLs[currentUTCDateKey] {
                                    habitImagePreviewItem = RemoteImagePreviewItem(title: habit.title, urlString: urlString)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { i in
                                viewModel.deleteHabit(habitService.habits[i])
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showAddHabit = true
                    } label: {
                        Label("Add Habit", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddHabit) {
                AddHabitView(viewModel: viewModel)
            }
            .onAppear {
                if let userId = authService.currentUser?.uid {
                    viewModel.startListening(userId: userId)
                }
            }
            .sheet(item: $habitForPhotoCompletion) { habit in
                CompletionPhotoSheet(
                    title: "Complete Habit",
                    subtitle: habit.title,
                    confirmTitle: "Complete Habit"
                ) { imageData in
                    if !viewModel.isCompletedToday(habit) {
                        viewModel.toggleHabit(habit, completionImageData: imageData)
                    }
                }
            }
            .sheet(item: $habitImagePreviewItem) { item in
                RemoteImagePreviewSheet(item: item)
            }
        }
    }
}

// MARK: - Habit Row

struct HabitRowView: View {
    let habit: HabitModel
    @ObservedObject var viewModel: HabitViewModel
    let onCompleteWithPhoto: () -> Void
    let onPreviewImage: () -> Void
    @State private var isExpanded = false

    private var completedToday: Bool {
        viewModel.isCompletedToday(habit)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Toggle circle
                Button {
                    viewModel.toggleHabit(habit)
                } label: {
                    Image(systemName: completedToday ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(completedToday ? .orange : .gray)
                }
                .buttonStyle(.plain)

                if !completedToday {
                    Button {
                        onCompleteWithPhoto()
                    } label: {
                        Image(systemName: "photo.badge.checkmark")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }

                // Habit title
                Text(habit.title)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()

                // Streak badge
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.subheadline)
                    Text("\(habit.currentStreak)")
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .padding(.leading, 4)
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                HabitHeatmapView(habit: habit)
                    .padding(.leading, 36)
            }

            // Best streak footnote
            if habit.bestStreak > 0 {
                Text("Best: \(habit.bestStreak) days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 36)
            }

            if completedToday,
               let todayPhotoURL = habit.completionImageURLs[currentUTCDateKey],
               !todayPhotoURL.isEmpty {
                Button {
                    onPreviewImage()
                } label: {
                    Label("Photo attached today", systemImage: "photo")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 36)
            }
        }
        .padding(.vertical, 6)
    }

    private var currentUTCDateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: Date())
    }
}
