//
//  ProfileView.swift
//  ABCD
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = ProfileViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                xpSection
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                statsSection
                quoteSection
                logoutButton
            }
            .padding()
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Profile")
        .onAppear {
            if let userId = authService.currentUser?.uid {
                viewModel.load(userId: userId)
            }
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
        HStack(spacing: 14) {
            Circle()
                .fill(Theme.Colors.accent.opacity(0.2))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(initials)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.accent)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(authService.userModel?.displayName ?? "Guest")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Level \(authService.userModel?.level ?? 0)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Theme.Colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Colors.stroke, lineWidth: 1)
        )
        .cornerRadius(14)
    }

    private var xpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total XP: \(authService.userModel?.xp ?? 0)")
                .font(.headline)
            XPProgressBar(
                xp: authService.userModel?.xp ?? 0,
                xpPerLevel: Constants.XP.xpPerLevel
            )
        }
        .padding()
        .background(Theme.Colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.Colors.stroke, lineWidth: 1)
        )
        .cornerRadius(14)
    }

    private var statsSection: some View {
        LazyVGrid(columns: columns, spacing: 12) {
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
        }
    }

    @ViewBuilder
    private var quoteSection: some View {
        if let quote = viewModel.quote {
            QuoteCard(quote: quote) {
                viewModel.refreshQuote()
            }
        } else if viewModel.isLoading {
            HStack {
                ProgressView()
                Text("Loading quote...")
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.Colors.stroke, lineWidth: 1)
            )
            .cornerRadius(14)
        } else {
            EmptyStateView(
                icon: "quote.bubble",
                title: "No Quote Available",
                message: "Pull to refresh or check your connection."
            )
            .frame(height: 150)
        }
    }

    private var logoutButton: some View {
        Button(role: .destructive) {
            authService.logout()
        } label: {
            Text("Log Out")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.12))
                .foregroundColor(.red)
                .cornerRadius(12)
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

    private func reloadProfileData() {
        guard let userId = authService.currentUser?.uid else { return }
        viewModel.load(userId: userId)
    }
}
