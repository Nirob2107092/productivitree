//
//  ProfileView.swift
//  ABCD
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var habitService = HabitService()
    @StateObject private var habitViewModel: HabitViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var displayedTreeStage: TreeStage = .seed
    @State private var displayedEnvironment: EnvironmentType = .normal

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    init() {
        let service = HabitService()
        _habitService = StateObject(wrappedValue: service)
        _habitViewModel = StateObject(wrappedValue: HabitViewModel(habitService: service))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                treeWorldSection
                xpSection

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                }

                statsSection
                quoteSection
                logoutButton
            }
            .padding(.horizontal)
            .padding(.vertical, 18)
        }
        .background(Theme.Gradients.appBackground.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if let userId = authService.currentUser?.uid {
                viewModel.load(userId: userId)
                habitViewModel.startListening(userId: userId)
            }
            syncTreeState(animated: false)
        }
        .onChange(of: authService.userModel?.treeStage) { _, _ in
            syncTreeState(animated: true)
        }
        .onChange(of: authService.userModel?.environment) { _, _ in
            syncTreeState(animated: true)
        }
        .onChange(of: authService.userModel?.xp) { _, _ in
            reloadProfileData()
        }
        .onChange(of: authService.userModel?.tasksCompleted) { _, _ in
            reloadProfileData()
        }
        .onChange(of: authService.userModel?.totalFocusMinutes) { _, _ in
            reloadProfileData()
        }
        .alert("Level Up", isPresented: $viewModel.showLevelUpAlert) {
            Button("Nice") { }
        } message: {
            Text(viewModel.levelUpMessage)
        }
    }

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.Gradients.hero)

            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 170, height: 170)
                .offset(x: 110, y: -60)

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 120, height: 120)
                .offset(x: -90, y: 80)

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 72, height: 72)

                        Text(initials)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(authService.userModel?.displayName ?? "Guest")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)

                        Text(authService.userModel?.email ?? "No email available")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.84))
                            .lineLimit(1)
                    }

                    Spacer()
                }

                HStack(spacing: 10) {
                    Label("Level \(authService.userModel?.level ?? 0)", systemImage: "sparkles")
                        .appChip(tint: .white)
                        .foregroundStyle(Color.white)
                        .background(Color.white.opacity(0.14), in: Capsule())

                    Label("\(authService.userModel?.xp ?? 0) XP", systemImage: "bolt.fill")
                        .appChip(tint: .white)
                        .foregroundStyle(Color.white)
                        .background(Color.white.opacity(0.14), in: Capsule())
                }
            }
            .padding(22)
        }
        .frame(height: 200)
        .shadow(color: Theme.Colors.accent.opacity(0.22), radius: 24, x: 0, y: 16)
    }

    private var treeWorldSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tree World")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Your progress is reflected as a living world with growth and atmosphere.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()
            }

            TreeView(stage: displayedTreeStage, environment: displayedEnvironment)
                .animation(.easeInOut(duration: 0.5), value: displayedTreeStage)
                .animation(.easeInOut(duration: 0.5), value: displayedEnvironment)

            HStack(spacing: 10) {
                Label(displayedTreeStage.rawValue.capitalized, systemImage: "tree.fill")
                    .appChip(tint: Theme.Colors.accent)

                Label(displayedEnvironment.rawValue.capitalized, systemImage: environmentSystemImage)
                    .appChip(tint: Theme.Colors.accentSecondary)
            }
        }
        .appCard(fill: Theme.Colors.surfaceStrong, padding: 20)
    }

    private var xpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Growth Progress")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Complete tasks, habits, and focus sessions to keep your world evolving.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                Text("\(authService.userModel?.xp ?? 0) XP")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.Colors.accent)
            }

            XPProgressBar(
                xp: authService.userModel?.xp ?? 0,
                xpPerLevel: Constants.XP.xpPerLevel
            )
        }
        .appCard(fill: LinearGradient(
            colors: [Color.white.opacity(0.94), Color(red: 0.92, green: 0.96, blue: 0.91)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ))
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Highlights")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.Colors.textPrimary)

            LazyVGrid(columns: columns, spacing: 14) {
                StatCard(
                    title: "Tasks Completed",
                    value: "\(viewModel.userStats.tasksCompleted)",
                    iconName: "checkmark.circle.fill",
                    tint: Theme.Colors.accent
                )

                StatCard(
                    title: "Focus Time",
                    value: viewModel.formattedFocusTime(),
                    iconName: "timer",
                    tint: Theme.Colors.accentSecondary
                )

                StatCard(
                    title: "Best Streak",
                    value: "\(viewModel.userStats.bestHabitStreak) days",
                    iconName: "flame.fill",
                    tint: Theme.Colors.warning
                )

                NavigationLink(destination: AnalyticsView(
                    focusSessions: viewModel.focusSessions,
                    completedTasks: viewModel.completedTasks,
                    habits: habitViewModel.habitService.habits
                )) {
                    StatCard(icon: "chart.bar.fill", title: "Analytics", value: "View Details", color: Theme.Colors.accentWarm)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var quoteSection: some View {
        if let quote = viewModel.quote {
            QuoteCard(quote: quote) {
                viewModel.refreshQuote()
            }
        } else if viewModel.isLoading {
            HStack(spacing: 12) {
                ProgressView()
                Text("Loading quote...")
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard(fill: Theme.Colors.surfaceStrong)
        } else {
            EmptyStateView(
                icon: "quote.bubble",
                title: "No Quote Available",
                message: "Pull to refresh or check your connection."
            )
            .frame(height: 180)
        }
    }

    private var logoutButton: some View {
        Button(role: .destructive) {
            authService.logout()
        } label: {
            Text("Log Out")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red.opacity(0.10))
                .foregroundColor(.red)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var initials: String {
        let name = authService.userModel?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if name.isEmpty {
            return "U"
        }

        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        let value = (first + second).uppercased()
        return value.isEmpty ? "U" : value
    }

    private var environmentSystemImage: String {
        switch displayedEnvironment {
        case .normal:
            return "cloud.sun.fill"
        case .sunny:
            return "sun.max.fill"
        case .rainy:
            return "cloud.rain.fill"
        case .night:
            return "moon.stars.fill"
        }
    }

    private func reloadProfileData() {
        guard let userId = authService.currentUser?.uid else { return }
        viewModel.load(userId: userId)
    }

    private func syncTreeState(animated: Bool) {
        let stage = authService.userModel?.treeStage ?? .seed
        let environment = authService.userModel?.environment ?? .normal

        if animated {
            withAnimation(.easeInOut(duration: 0.5)) {
                displayedTreeStage = stage
                displayedEnvironment = environment
            }
        } else {
            displayedTreeStage = stage
            displayedEnvironment = environment
        }
    }
}
