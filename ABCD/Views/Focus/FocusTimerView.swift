//
//  FocusTimerView.swift
//  ABCD
//

import SwiftUI

struct FocusTimerView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var focusService: FocusService
    @StateObject private var viewModel: FocusViewModel
    @StateObject private var soundService = AmbientSoundService()
    @State private var showSessionSetup = false
    @State private var showSoundSheet = false

    init() {
        let service = FocusService()
        _focusService = StateObject(wrappedValue: service)
        _viewModel = StateObject(wrappedValue: FocusViewModel(focusService: service))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    timerRing
                        .padding(.top, 8)

                    modePicker

                    controlButtons

                    pomodoroSection
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("Focus")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSessionSetup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSoundSheet = true
                    } label: {
                        Image(systemName: soundService.currentSound == nil
                              ? "speaker.slash"
                              : "speaker.wave.2.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        FocusHistoryView(focusService: focusService)
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showSessionSetup) {
                FocusSessionSetupSheet(viewModel: viewModel)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showSoundSheet) {
                AmbientSoundSheet(service: soundService)
                    .presentationDetents([.medium, .large])
            }
            .onAppear {
                if let userId = authService.currentUser?.uid {
                    viewModel.activeUserId = userId
                    viewModel.startListening(userId: userId)
                }
            }
            .alert("Session Complete! 🎉", isPresented: $viewModel.showCompletionAlert) {
                Button("Great!", role: .cancel) { }
            } message: {
                Text("You completed a \(viewModel.focusMinutes)-minute \(viewModel.selectedMode.displayName) session.")
            }
        }
    }

    // MARK: - Timer Ring

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 14)

            Circle()
                .trim(from: 0, to: CGFloat(viewModel.progress))
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: viewModel.progress)
                .animation(.easeInOut(duration: 0.4), value: ringColor)

            VStack(spacing: 8) {
                Image(systemName: centerIcon)
                    .font(.title2)
                    .foregroundColor(ringColor)

                Text(viewModel.formattedTime)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(viewModel.phaseLabel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Focus \(viewModel.focusMinutes) min - Break \(viewModel.breakMinutes) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 260, height: 260)
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        HStack(spacing: 10) {
            ForEach(FocusMode.allCases, id: \.self) { mode in
                Button {
                    viewModel.selectMode(mode)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: mode.iconName)
                            .font(.title3)
                        Text(mode.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        viewModel.selectedMode == mode
                            ? color(for: mode).opacity(0.2)
                            : Color.gray.opacity(0.08)
                    )
                    .foregroundColor(
                        viewModel.selectedMode == mode
                            ? color(for: mode)
                            : .primary
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isRunning)
                .opacity(viewModel.isRunning && viewModel.selectedMode != mode ? 0.4 : 1)
            }
        }
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 12) {
            Button {
                if viewModel.isRunning {
                    viewModel.pause()
                } else {
                    viewModel.start()
                }
            } label: {
                HStack {
                    Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                    Text(viewModel.isRunning ? "Pause" : "Start")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ringColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            Button {
                viewModel.reset()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.15))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Pomodoro Section

    private var pomodoroSection: some View {
        VStack(spacing: 12) {
            Toggle(isOn: Binding(
                get: { viewModel.pomodoroEnabled },
                set: { viewModel.setPomodoroEnabled($0) }
            )) {
                HStack(spacing: 10) {
                    Image(systemName: "repeat.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pomodoro Cycle")
                            .fontWeight(.medium)
                        Text("Custom focus and break durations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .tint(.red)
            .disabled(viewModel.isRunning)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)

            if viewModel.pomodoroEnabled {
                HStack(spacing: 10) {
                    ForEach(1...FocusViewModel.totalPomodoroCycles, id: \.self) { i in
                        Circle()
                            .fill(i <= viewModel.completedWorkCount ? Color.green : Color.gray.opacity(0.2))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.green.opacity(0.4), lineWidth: i == viewModel.completedWorkCount + 1 && viewModel.pomodoroPhase == .work ? 2 : 0)
                            )
                            .animation(.easeInOut, value: viewModel.completedWorkCount)
                    }
                }
            }
        }
    }

    // MARK: - Colors & Icons

    private var ringColor: Color {
        if viewModel.phaseIsBreak {
            return .green
        }
        return color(for: viewModel.selectedMode)
    }

    private var centerIcon: String {
        if viewModel.phaseIsBreak {
            return viewModel.pomodoroPhase == .longBreak ? "leaf.fill" : "cup.and.saucer.fill"
        }
        return viewModel.selectedMode.iconName
    }

    private func color(for mode: FocusMode) -> Color {
        switch mode {
        case .deepWork: return .purple
        case .learning: return .blue
        case .creating: return .orange
        }
    }
}

private struct FocusSessionSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FocusViewModel

    @State private var selectedMode: FocusMode = .deepWork
    @State private var focusMinutes: Int = 25
    @State private var breakMinutes: Int = 5

    var body: some View {
        NavigationStack {
            Form {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mode")
                        .font(.headline)

                    Picker("Mode", selection: $selectedMode) {
                        ForEach(FocusMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Durations")
                        .font(.headline)

                    Stepper("Focus time: \(focusMinutes) min", value: $focusMinutes, in: 5...180, step: 5)
                    Stepper("Break time: \(breakMinutes) min", value: $breakMinutes, in: 1...60, step: 1)

                    Text("These values are applied to the timer and Pomodoro breaks.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button {
                        applySettings()
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("New Focus Session")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                selectedMode = viewModel.selectedMode
                focusMinutes = viewModel.focusMinutes
                breakMinutes = viewModel.breakMinutes
            }
        }
    }

    private func applySettings() {
        viewModel.configureSession(
            mode: selectedMode,
            focusMinutes: focusMinutes,
            breakMinutes: breakMinutes
        )
        dismiss()
    }
}
