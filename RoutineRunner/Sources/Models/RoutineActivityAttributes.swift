import ActivityKit
import Foundation

struct RoutineActivityAttributes: ActivityAttributes {
    let routineTitle: String
    let totalSteps: Int

    struct ContentState: Codable, Hashable {
        let stepName: String
        let stepIndex: Int
        /// The wall-clock date when the current step's timer reaches zero.
        /// Used by `Text(timerInterval:countsDown:)` for a truly live countdown.
        let stepEndDate: Date
        let isPaused: Bool
        /// Snapshot of remaining seconds so the widget can display a frozen value when paused.
        let remainingSeconds: Int
    }
}
