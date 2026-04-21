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
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerCard
                    timerRing
                    modePicker
                    controlButtons
                    pomodoroSection
                }
                .padding(.horizontal)
                .padding(.vertical, 18)
            }
            .background(Theme.Gradients.appBackground.ignoresSafeArea())
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.large)
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
            .alert("Session Complete!", isPresented: $viewModel.showCompletionAlert) {
                Button("Great!", role: .cancel) { }
            } message: {
                Text("You completed a \(viewModel.focusMinutes)-minute \(viewModel.selectedMode.displayName) session.")
            }
        }
    }

    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Protect your best work block")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(viewModel.phaseIsBreak ? "Recovery is part of progress." : "Pick a mode and enter deep focus.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            Label(viewModel.selectedMode.displayName, systemImage: viewModel.selectedMode.iconName)
                .appChip(tint: ringColor)
        }
        .appCard(fill: Theme.Colors.surfaceStrong)
    }

    private var timerRing: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.92),
                            ringColor.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .stroke(Color.gray.opacity(0.10), lineWidth: 16)

            Circle()
                .trim(from: 0, to: CGFloat(viewModel.progress))
                .stroke(
                    AngularGradient(
                        colors: [ringColor.opacity(0.55), ringColor, ringColor.opacity(0.75)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: viewModel.progress)
                .animation(.easeInOut(duration: 0.4), value: ringColor)

            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(ringColor.opacity(0.12))
                        .frame(width: 54, height: 54)

                    Image(systemName: centerIcon)
                        .font(.title2)
                        .foregroundColor(ringColor)
                }

                Text(viewModel.formattedTime)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(viewModel.phaseLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Theme.Colors.textSecondary)

                Text("Focus \(viewModel.focusMinutes)m  |  Break \(viewModel.breakMinutes)m")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .frame(height: 350)
        .appCard(fill: Theme.Colors.surfaceStrong, padding: 24)
    }

    private var modePicker: some View {
        HStack(spacing: 10) {
            ForEach(FocusMode.allCases, id: \.self) { mode in
                Button {
                    viewModel.selectMode(mode)
                } label: {
                    VStack(spacing: 7) {
                        Image(systemName: mode.iconName)
                            .font(.title3)
                        Text(mode.displayName)
                            .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                viewModel.selectedMode == mode
                                    ? color(for: mode).opacity(0.14)
                                    : Color.white.opacity(0.7)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(viewModel.selectedMode == mode ? color(for: mode).opacity(0.35) : Theme.Colors.stroke, lineWidth: 1)
                    )
                    .foregroundColor(viewModel.selectedMode == mode ? color(for: mode) : Theme.Colors.textPrimary)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isRunning)
                .opacity(viewModel.isRunning && viewModel.selectedMode != mode ? 0.45 : 1)
            }
        }
    }

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
                .padding(.vertical, 16)
                .background(Theme.Gradients.accent)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.8))
                .foregroundColor(Theme.Colors.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Theme.Colors.stroke, lineWidth: 1)
                )
            }
        }
    }

    private var pomodoroSection: some View {
        VStack(spacing: 16) {
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
                            .foregroundColor(Theme.Colors.textPrimary)
                        Text("Custom focus and break durations")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }
            .tint(.red)
            .disabled(viewModel.isRunning)

            if viewModel.pomodoroEnabled {
                HStack(spacing: 10) {
                    ForEach(1...FocusViewModel.totalPomodoroCycles, id: \.self) { i in
                        Circle()
                            .fill(i <= viewModel.completedWorkCount ? Theme.Colors.success : Color.gray.opacity(0.18))
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Theme.Colors.success.opacity(0.45), lineWidth: i == viewModel.completedWorkCount + 1 && viewModel.pomodoroPhase == .work ? 2 : 0)
                            )
                            .animation(.easeInOut, value: viewModel.completedWorkCount)
                    }
                }

                Text(viewModel.phaseIsBreak ? "Enjoy the break, then jump back in." : "Each completed work block moves you closer to a full cycle.")
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .appCard(fill: Theme.Colors.surfaceStrong)
    }

    private var ringColor: Color {
        if viewModel.phaseIsBreak {
            return Theme.Colors.success
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
        case .deepWork: return Color(red: 0.42, green: 0.37, blue: 0.86)
        case .learning: return Theme.Colors.accentSecondary
        case .creating: return Theme.Colors.accentWarm
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
