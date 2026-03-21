import AppIntents
import ActivityKit
import Foundation

// MARK: - Toggle Play / Pause


struct TogglePlayPauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Toggle Play/Pause"
    static var description: IntentDescription = "Pauses or resumes the current routine step timer."

    func perform() async throws -> some IntentResult {
        guard var state = RoutineTimerState.load() else { return .result() }

        if state.isPaused {
            // Resume: compute a new stepEndDate from the frozen remainingSeconds
            let newEndDate = Date().addingTimeInterval(TimeInterval(state.remainingSeconds))
            state = RoutineTimerState(
                routineTitle: state.routineTitle,
                totalSteps: state.totalSteps,
                stepName: state.stepName,
                stepIndex: state.stepIndex,
                stepEndDate: newEndDate,
                isPaused: false,
                remainingSeconds: state.remainingSeconds,
                stepNames: state.stepNames,
                stepDurations: state.stepDurations
            )
        } else {
            // Pause: snapshot remaining seconds from the live stepEndDate
            let remaining = Int(max(0, state.stepEndDate.timeIntervalSinceNow))
            state = RoutineTimerState(
                routineTitle: state.routineTitle,
                totalSteps: state.totalSteps,
                stepName: state.stepName,
                stepIndex: state.stepIndex,
                stepEndDate: state.stepEndDate,
                isPaused: true,
                remainingSeconds: remaining,
                stepNames: state.stepNames,
                stepDurations: state.stepDurations
            )
        }

        state.save()
        await updateLiveActivity(from: state)
        return .result()
    }
}

// MARK: - Skip Step


struct SkipStepIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Skip Step"
    static var description: IntentDescription = "Skips to the next step in the routine."

    func perform() async throws -> some IntentResult {
        guard let state = RoutineTimerState.load() else { return .result() }

        let nextIndex = state.stepIndex + 1
        guard nextIndex < state.totalSteps,
              nextIndex < state.stepDurations.count,
              nextIndex < state.stepNames.count else {
            // Last step — can't skip further from the widget; app handles completion
            return .result()
        }

        let nextDuration = state.stepDurations[nextIndex]
        let newEndDate = Date().addingTimeInterval(nextDuration)
        let newState = RoutineTimerState(
            routineTitle: state.routineTitle,
            totalSteps: state.totalSteps,
            stepName: state.stepNames[nextIndex],
            stepIndex: nextIndex,
            stepEndDate: newEndDate,
            isPaused: false,
            remainingSeconds: Int(nextDuration),
            stepNames: state.stepNames,
            stepDurations: state.stepDurations
        )

        newState.save()
        await updateLiveActivity(from: newState)
        return .result()
    }
}

// MARK: - Helpers


private func updateLiveActivity(from state: RoutineTimerState) async {
    let contentState = RoutineActivityAttributes.ContentState(
        stepName: state.stepName,
        stepIndex: state.stepIndex,
        stepEndDate: state.stepEndDate,
        isPaused: state.isPaused,
        remainingSeconds: state.remainingSeconds
    )
    for activity in Activity<RoutineActivityAttributes>.activities {
        await activity.update(.init(state: contentState, staleDate: nil))
    }
}
