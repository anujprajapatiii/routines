import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    private var currentActivity: Activity<RoutineActivityAttributes>?

    func startActivity(
        routineTitle: String,
        totalSteps: Int,
        stepName: String,
        stepIndex: Int,
        remainingSeconds: TimeInterval
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = RoutineActivityAttributes(
            routineTitle: routineTitle,
            totalSteps: totalSteps
        )
        let state = RoutineActivityAttributes.ContentState(
            stepName: stepName,
            stepIndex: stepIndex,
            timerEnd: Date().addingTimeInterval(remainingSeconds),
            isPaused: false
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    func updateActivity(
        stepName: String,
        stepIndex: Int,
        remainingSeconds: TimeInterval,
        isPaused: Bool
    ) {
        let state = RoutineActivityAttributes.ContentState(
            stepName: stepName,
            stepIndex: stepIndex,
            timerEnd: Date().addingTimeInterval(remainingSeconds),
            isPaused: isPaused
        )
        Task {
            await currentActivity?.update(.init(state: state, staleDate: nil))
        }
    }

    func endActivity() {
        Task {
            let finalState = RoutineActivityAttributes.ContentState(
                stepName: "Complete",
                stepIndex: 0,
                timerEnd: Date(),
                isPaused: true
            )
            await currentActivity?.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            currentActivity = nil
        }
    }
}
