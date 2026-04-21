//
//  FocusViewModel.swift
//  ABCD
//

import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

enum PomodoroPhase: String {
    case idle
    case work
    case shortBreak
    case longBreak

    var isBreak: Bool { self == .shortBreak || self == .longBreak }
}

class FocusViewModel: ObservableObject {
    // Timer state
    @Published var timeRemaining: Int
    @Published var totalSeconds: Int
    @Published var isRunning: Bool = false
    @Published var selectedMode: FocusMode = .deepWork
    @Published var focusMinutes: Int
    @Published var breakMinutes: Int
    @Published var showCompletionAlert: Bool = false

    // Pomodoro state
    @Published var pomodoroEnabled: Bool = false
    @Published var pomodoroPhase: PomodoroPhase = .idle
    @Published var pomodoroCycle: Int = 1  // 1...totalPomodoroCycles

    /// Set by the view from the authenticated user once it appears.
    var activeUserId: String?

    let focusService: FocusService

    private var timerCancellable: AnyCancellable?

    static let totalPomodoroCycles = 4

    init(focusService: FocusService) {
        self.focusService = focusService
        let initialFocusMinutes = 25
        let initialBreakMinutes = 5
        let defaultSeconds = initialFocusMinutes * 60
        self.focusMinutes = initialFocusMinutes
        self.breakMinutes = initialBreakMinutes
        self.totalSeconds = defaultSeconds
        self.timeRemaining = defaultSeconds
    }

    // MARK: - Listening

    func startListening(userId: String) {
        focusService.fetchSessionHistory(userId: userId)
    }

    // MARK: - Controls

    func start() {
        guard !isRunning, timeRemaining > 0 else { return }
        isRunning = true
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func pause() {
        isRunning = false
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func reset() {
        pause()
        if pomodoroEnabled {
            pomodoroCycle = 1
            pomodoroPhase = .work
        }
        applyDurationForCurrentPhase()
    }

    func selectMode(_ mode: FocusMode) {
        guard !isRunning else { return }
        selectedMode = mode
    }

    func configureSession(mode: FocusMode, focusMinutes: Int, breakMinutes: Int) {
        guard !isRunning else { return }
        selectedMode = mode
        self.focusMinutes = focusMinutes
        self.breakMinutes = breakMinutes
        if pomodoroEnabled {
            pomodoroPhase = .work
            pomodoroCycle = 1
        }
        applyDurationForCurrentPhase()
    }

    // MARK: - Pomodoro

    func setPomodoroEnabled(_ enabled: Bool) {
        guard !isRunning else { return }
        pomodoroEnabled = enabled
        if enabled {
            pomodoroPhase = .work
            pomodoroCycle = 1
        } else {
            pomodoroPhase = .idle
            pomodoroCycle = 1
        }
        applyDurationForCurrentPhase()
    }

    private func advancePomodoroPhase() {
        switch pomodoroPhase {
        case .work:
            pomodoroPhase = pomodoroCycle >= Self.totalPomodoroCycles ? .longBreak : .shortBreak
        case .shortBreak:
            pomodoroCycle += 1
            pomodoroPhase = .work
        case .longBreak:
            pomodoroCycle = 1
            pomodoroPhase = .work
        case .idle:
            pomodoroPhase = .work
        }
        applyDurationForCurrentPhase()
        // Auto-start the next phase — the hallmark of Pomodoro
        start()
    }

    private func applyDurationForCurrentPhase() {
        let minutes = pomodoroEnabled && pomodoroPhase.isBreak ? breakMinutes : focusMinutes
        totalSeconds = minutes * 60
        timeRemaining = totalSeconds
    }

    // MARK: - Tick

    private func tick() {
        guard timeRemaining > 0 else {
            onComplete()
            return
        }
        timeRemaining -= 1
        if timeRemaining == 0 {
            onComplete()
        }
    }

    // MARK: - Completion

    func onComplete() {
        pause()
        triggerHaptic()

        // Save a session record only for productive (non-break) phases.
        let wasWorkPhase = !pomodoroEnabled || pomodoroPhase == .work

        if wasWorkPhase, let userId = activeUserId {
            let minutes = focusMinutes
            let session = FocusSessionModel(
                id: UUID().uuidString,
                userId: userId,
                durationMinutes: minutes,
                breakMinutes: breakMinutes,
                mode: selectedMode,
                completedAt: Date()
            )
            focusService.saveSession(session: session)
            focusService.updateTotalFocusTime(userId: userId, minutes: minutes)
            GamificationService.shared.registerActivity(userId: userId, at: Date())
        }

        if pomodoroEnabled {
            advancePomodoroPhase()
        } else {
            showCompletionAlert = true
            applyDurationForCurrentPhase()
        }
    }

    // MARK: - Display Helpers

    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1 - (Double(timeRemaining) / Double(totalSeconds))
    }

    var completedWorkCount: Int {
        guard pomodoroEnabled else { return 0 }
        switch pomodoroPhase {
        case .work, .idle: return pomodoroCycle - 1
        case .shortBreak: return pomodoroCycle
        case .longBreak: return Self.totalPomodoroCycles
        }
    }

    var phaseLabel: String {
        if pomodoroEnabled {
            switch pomodoroPhase {
            case .work: return "Focus \(pomodoroCycle) of \(Self.totalPomodoroCycles)"
            case .shortBreak: return "Short Break"
            case .longBreak: return "Long Break"
            case .idle: return selectedMode.displayName
            }
        }
        return selectedMode.displayName
    }

    var phaseIsBreak: Bool {
        pomodoroEnabled && pomodoroPhase.isBreak
    }

    private func triggerHaptic() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
