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
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Build momentum daily")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Theme.Colors.textPrimary)

                            Text("\(habitService.habits.count) active habits in rotation")
                                .font(.subheadline)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }

                        Spacer()

                        ZStack {
                            Circle()
                                .fill(Theme.Colors.warning.opacity(0.14))
                                .frame(width: 46, height: 46)

                            Image(systemName: "flame.fill")
                                .font(.headline)
                                .foregroundStyle(Theme.Colors.warning)
                        }
                    }
                }
                .appCard(fill: Theme.Colors.surfaceStrong)

                if habitService.habits.isEmpty {
                    EmptyStateView(
                        icon: "flame",
                        title: "No Habits Yet",
                        message: "Tap + to create your first habit and start building streaks!"
                    )
                    .frame(maxHeight: .infinity)
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
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 7, leading: 0, bottom: 7, trailing: 0))
                            .listRowBackground(Color.clear)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { i in
                                viewModel.deleteHabit(habitService.habits[i])
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .padding(.horizontal)
            .padding(.top, 14)
            .background(Theme.Gradients.appBackground.ignoresSafeArea())
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showAddHabit = true
                    } label: {
                        Label("Add Habit", systemImage: "plus")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(Theme.Colors.warning)
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

    private var currentUTCDateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: Date())
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
                Button {
                    viewModel.toggleHabit(habit)
                } label: {
                    ZStack {
                        Circle()
                            .fill((completedToday ? Theme.Colors.warning : Theme.Colors.surfaceAlt).opacity(0.20))
                            .frame(width: 38, height: 38)

                        Image(systemName: completedToday ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(completedToday ? Theme.Colors.warning : Theme.Colors.textSecondary)
                    }
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

                Text(habit.title)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.warning)
                    Text("\(habit.currentStreak)")
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.warning)
                    Text("days")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.Colors.warning.opacity(0.12))
                .cornerRadius(10)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Theme.Colors.textSecondary)
                        .font(.caption)
                        .padding(.leading, 4)
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                HabitHeatmapView(habit: habit)
                    .padding(.leading, 36)
            }

            if habit.bestStreak > 0 {
                Text("Best: \(habit.bestStreak) days")
                    .font(.caption2)
                    .foregroundColor(Theme.Colors.textSecondary)
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
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 36)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .appCard(fill: Theme.Colors.surfaceStrong, padding: 0)
    }

    private var currentUTCDateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: Date())
    }
}
