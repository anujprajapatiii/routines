import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    private var activity: Activity<RoutineActivityAttributes>?

    func startActivity(routineTitle: String, totalSteps: Int, state: RoutineTimerState) {
        // End any lingering activities before starting a new one
        endAllActivities()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = RoutineActivityAttributes(
            routineTitle: routineTitle,
            totalSteps: totalSteps
        )
        let contentState = RoutineActivityAttributes.ContentState(
            stepName: state.stepName,
            stepIndex: state.stepIndex,
            stepEndDate: state.stepEndDate,
            isPaused: state.isPaused,
            remainingSeconds: state.remainingSeconds
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    func updateActivity(state: RoutineTimerState) {
        let contentState = RoutineActivityAttributes.ContentState(
            stepName: state.stepName,
            stepIndex: state.stepIndex,
            stepEndDate: state.stepEndDate,
            isPaused: state.isPaused,
            remainingSeconds: state.remainingSeconds
        )

        Task {
            await activity?.update(.init(state: contentState, staleDate: nil))
        }
    }

    func endActivity() {
        endAllActivities()
    }

    /// End every live activity of this type, not just the one we hold a reference to.
    private func endAllActivities() {
        let current = activity
        activity = nil
        Task {
            await current?.end(nil, dismissalPolicy: .immediate)
            for activity in Activity<RoutineActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
