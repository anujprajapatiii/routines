import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    private var activity: Activity<RoutineActivityAttributes>?

    func startActivity(routineTitle: String, totalSteps: Int, stepName: String, stepIndex: Int, remainingSeconds: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = RoutineActivityAttributes(
            routineTitle: routineTitle,
            totalSteps: totalSteps
        )
        let state = RoutineActivityAttributes.ContentState(
            stepName: stepName,
            stepIndex: stepIndex,
            remainingSeconds: remainingSeconds,
            isPaused: false
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil)
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    func updateActivity(stepName: String, stepIndex: Int, remainingSeconds: Int, isPaused: Bool) {
        let state = RoutineActivityAttributes.ContentState(
            stepName: stepName,
            stepIndex: stepIndex,
            remainingSeconds: remainingSeconds,
            isPaused: isPaused
        )

        Task {
            await activity?.update(.init(state: state, staleDate: nil))
        }
    }

    func endActivity() {
        Task {
            await activity?.end(nil, dismissalPolicy: .immediate)
            activity = nil
        }
    }
}
