import SwiftUI
import UIKit
import Combine

// MARK: - ViewModel

@MainActor
final class RoutinePlayerViewModel: ObservableObject {
    let routine: Routine
    let hapticsEnabled: Bool

    @Published var currentStepIndex: Int = 0
    @Published var remainingSeconds: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var isComplete: Bool = false

    /// The wall-clock date when the current step's timer hits zero.
    /// This is the single source of truth — `remainingSeconds` is derived from it.
    private var stepEndDate: Date = .distantFuture

    /// Wall-clock elapsed time tracked via Date
    private var pausedElapsed: TimeInterval = 0
    private var lastResumeDate: Date?

    var totalElapsedTime: TimeInterval {
        let running = lastResumeDate.map { Date().timeIntervalSince($0) } ?? 0
        return pausedElapsed + running
    }

    var overallProgress: Double {
        guard routine.totalDuration > 0 else { return 0 }
        let completedTime = routine.steps.prefix(currentStepIndex).reduce(0) { $0 + $1.duration }
        let currentStepElapsed = currentStep.duration - remainingSeconds
        return (completedTime + currentStepElapsed) / routine.totalDuration
    }

    var currentStep: Step {
        routine.steps[currentStepIndex]
    }

    var stepProgress: Double {
        guard currentStep.duration > 0 else { return 0 }
        return 1.0 - (remainingSeconds / currentStep.duration)
    }

    private let liveActivity = LiveActivityManager()
    private var timerCancellable: AnyCancellable?
    private var lifecycleCancellables = Set<AnyCancellable>()

    init(routine: Routine, hapticsEnabled: Bool = true) {
        self.routine = routine
        self.hapticsEnabled = hapticsEnabled
        self.remainingSeconds = routine.steps.first?.duration ?? 0
        observeAppLifecycle()
    }

    func start() {
        lastResumeDate = Date()
        stepEndDate = Date().addingTimeInterval(remainingSeconds)
        syncSharedState()
        liveActivity.startActivity(
            routineTitle: routine.title,
            totalSteps: routine.steps.count,
            state: currentSharedState()
        )
        play()
    }

    func togglePlayPause() {
        if isRunning { pause() } else { play() }
    }

    func play() {
        guard !isComplete else { return }
        isRunning = true
        lastResumeDate = Date()
        // Recompute stepEndDate from current remainingSeconds
        stepEndDate = Date().addingTimeInterval(remainingSeconds)
        syncSharedState()
        updateLiveActivity()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func pause() {
        isRunning = false
        // Snapshot remaining time from stepEndDate before it becomes stale
        remainingSeconds = max(0, stepEndDate.timeIntervalSinceNow)
        if let resume = lastResumeDate {
            pausedElapsed += Date().timeIntervalSince(resume)
        }
        lastResumeDate = nil
        timerCancellable?.cancel()
        timerCancellable = nil
        syncSharedState()
        updateLiveActivity()
    }

    func skipForward() {
        guard currentStepIndex < routine.steps.count - 1 else {
            complete()
            return
        }
        currentStepIndex += 1
        remainingSeconds = currentStep.duration
        stepEndDate = Date().addingTimeInterval(remainingSeconds)
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        syncSharedState()
        updateLiveActivity()
    }

    func addTime(_ seconds: TimeInterval = 120) {
        remainingSeconds += seconds
        stepEndDate = stepEndDate.addingTimeInterval(seconds)
        syncSharedState()
        updateLiveActivity()
    }

    private func tick() {
        // Derive remaining from the canonical stepEndDate
        remainingSeconds = max(0, stepEndDate.timeIntervalSinceNow)
        if remainingSeconds <= 0 {
            if currentStepIndex >= routine.steps.count - 1 {
                complete()
            } else {
                skipForward()
            }
        }
    }

    private func complete() {
        pause()
        isComplete = true
        if hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        liveActivity.endActivity()
        RoutineTimerState.clear()
    }

    private func currentSharedState() -> RoutineTimerState {
        RoutineTimerState(
            routineTitle: routine.title,
            totalSteps: routine.steps.count,
            stepName: currentStep.title,
            stepIndex: currentStepIndex,
            stepEndDate: stepEndDate,
            isPaused: !isRunning,
            remainingSeconds: Int(remainingSeconds),
            stepNames: routine.steps.map(\.title),
            stepDurations: routine.steps.map(\.duration)
        )
    }

    private func syncSharedState() {
        currentSharedState().save()
    }

    private func updateLiveActivity() {
        let state = currentSharedState()
        liveActivity.updateActivity(state: state)
    }

    private func observeAppLifecycle() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.restoreFromSharedState()
            }
            .store(in: &lifecycleCancellables)
    }

    /// When the app comes back from background, re-derive everything
    /// from the canonical stepEndDate stored in shared state.
    /// Also picks up pause/play/skip actions performed via Live Activity intents.
    private func restoreFromSharedState() {
        guard let saved = RoutineTimerState.load() else { return }

        // Pick up intent-driven pause/play changes
        let wasPausedByIntent = saved.isPaused && isRunning
        let wasResumedByIntent = !saved.isPaused && !isRunning

        currentStepIndex = saved.stepIndex
        stepEndDate = saved.stepEndDate

        if saved.isPaused {
            // Intent paused the timer — adopt the frozen remaining seconds
            remainingSeconds = TimeInterval(saved.remainingSeconds)
            if wasPausedByIntent {
                isRunning = false
                if let resume = lastResumeDate {
                    pausedElapsed += Date().timeIntervalSince(resume)
                }
                lastResumeDate = nil
                timerCancellable?.cancel()
                timerCancellable = nil
            }
            syncSharedState()
            updateLiveActivity()
        } else {
            remainingSeconds = max(0, stepEndDate.timeIntervalSinceNow)

            // Walk forward through steps if time has elapsed past current step
            while remainingSeconds <= 0 && currentStepIndex < routine.steps.count - 1 {
                currentStepIndex += 1
                let stepDuration = routine.steps[currentStepIndex].duration
                stepEndDate = stepEndDate.addingTimeInterval(stepDuration)
                remainingSeconds = max(0, stepEndDate.timeIntervalSinceNow)
            }

            if remainingSeconds <= 0 {
                complete()
            } else {
                if wasResumedByIntent {
                    play()
                } else {
                    syncSharedState()
                    updateLiveActivity()
                }
            }
        }
    }
}

// MARK: - View

struct RoutinePlayerView: View {
    @StateObject private var viewModel: RoutinePlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var routineCompleted: Bool
    var onComplete: ((CompletionRecord) -> Void)?

    init(routine: Routine, routineCompleted: Binding<Bool>, hapticsEnabled: Bool = true, onComplete: ((CompletionRecord) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: RoutinePlayerViewModel(routine: routine, hapticsEnabled: hapticsEnabled))
        _routineCompleted = routineCompleted
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                if viewModel.isComplete {
                    completionView
                } else {
                    playerView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.isComplete {
                        Button("Close") { dismiss() }
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(viewModel.routine.title)
                        .font(.headline)
                }
            }
            .onAppear {
                viewModel.start()
            }
        }
    }

    // MARK: - Player

    private var playerView: some View {
        VStack(spacing: 0) {
            // Top: progress bar
            overallProgressBar
                .padding(.horizontal)
                .padding(.top, 8)

            // Center: fixed layout for step info + timer + notes
            VStack(spacing: 16) {
                Spacer()

                stepHeader
                    .frame(height: 56)

                circularTimer

                notesSection
                    .frame(height: 60, alignment: .top)

                Spacer()
            }

            // Bottom: controls pinned
            controlsBar
                .padding(.bottom, 8)
        }
        .padding(.horizontal)
    }

    private var overallProgressBar: some View {
        VStack(spacing: 6) {
            ProgressView(value: viewModel.overallProgress)
                .tint(.accentColor)
            HStack {
                Text("Step \(viewModel.currentStepIndex + 1) of \(viewModel.routine.steps.count)")
                Spacer()
                Text(formatDuration(viewModel.routine.totalDuration * (1 - viewModel.overallProgress)) + " left")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var stepHeader: some View {
        Text(viewModel.currentStep.title)
            .font(.title2.weight(.bold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private var circularTimer: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 12)

            Circle()
                .trim(from: 0, to: viewModel.stepProgress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text(timeString(viewModel.remainingSeconds))
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .contentTransition(.numericText())
                Text("remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 220, height: 220)
        .id(viewModel.currentStepIndex)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !viewModel.currentStep.notes.isEmpty {
                ForEach(viewModel.currentStep.notes.indices, id: \.self) { i in
                    let note = viewModel.currentStep.notes[i]
                    if let link = note.link {
                        Link(destination: link) {
                            HStack(spacing: 6) {
                                Image(systemName: "link")
                                    .font(.caption)
                                Text(note.text)
                                    .font(.subheadline)
                            }
                        }
                    } else {
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .foregroundStyle(.tertiary)
                            Text(note.text)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }

    private var controlsBar: some View {
        HStack(spacing: 28) {
            Button { viewModel.addTime() } label: {
                Text("+2m")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.secondary.opacity(0.1), in: Capsule())
            }
            .foregroundStyle(.primary)

            Button { viewModel.togglePlayPause() } label: {
                Image(systemName: viewModel.isRunning ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
            }

            Button { viewModel.skipForward() } label: {
                Text("Done")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
            Text("Routine Complete!")
                .font(.title2.weight(.bold))
            Text(viewModel.routine.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Total time: \(formatDuration(viewModel.totalElapsedTime))")
                .font(.headline)
                .padding(.top, 4)
            Button("Done") {
                let record = CompletionRecord(
                    routineFileName: viewModel.routine.fileName,
                    routineTitle: viewModel.routine.title,
                    elapsedSeconds: viewModel.totalElapsedTime,
                    expectedSeconds: viewModel.routine.totalDuration
                )
                onComplete?(record)
                routineCompleted = true
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
    }

    // MARK: - Helpers

    private func timeString(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
