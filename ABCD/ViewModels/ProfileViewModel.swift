//
//  ProfileViewModel.swift
//  ABCD
//

import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var userStats: UserStats = .empty
    @Published var quote: Quote?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showLevelUpAlert = false
    @Published var levelUpMessage = ""

    private let quoteService: QuoteService
    private let userStatsService: UserStatsService
    private var cancellables = Set<AnyCancellable>()
    private var activeUserId: String?

    init(
        quoteService: QuoteService = QuoteService(),
        userStatsService: UserStatsService = UserStatsService()
    ) {
        self.quoteService = quoteService
        self.userStatsService = userStatsService
        observeLevelUp()
    }

    func load(userId: String) {
        activeUserId = userId
        isLoading = true
        errorMessage = nil

        Task {
            do {
                async let statsTask = userStatsService.fetchUserStats(userId: userId)
                async let quoteTask = quoteService.fetchQuote()

                let (stats, fetchedQuote) = try await (statsTask, quoteTask)
                userStats = stats
                quote = fetchedQuote
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Could not load profile data."
            }
        }
    }

    func refreshQuote() {
        Task {
            do {
                quote = try await quoteService.fetchQuote()
            } catch {
                errorMessage = "Could not refresh quote."
            }
        }
    }

    func formattedFocusTime() -> String {
        let minutes = userStats.totalFocusMinutes
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours == 0 {
            return "\(remainingMinutes)m"
        }
        return "\(hours)h \(remainingMinutes)m"
    }

    private func observeLevelUp() {
        NotificationCenter.default.publisher(for: .didLevelUp)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                let eventUserId = notification.userInfo?["userId"] as? String
                if let activeUserId = self.activeUserId, let eventUserId = eventUserId, activeUserId != eventUserId {
                    return
                }
                let newLevel = notification.userInfo?["newLevel"] as? Int ?? 0
                self.levelUpMessage = "You reached Level \(newLevel)!"
                self.showLevelUpAlert = true
            }
            .store(in: &cancellables)
    }
}
