import ActivityKit
import Foundation

struct RoutineActivityAttributes: ActivityAttributes {
    let routineTitle: String
    let totalSteps: Int

    struct ContentState: Codable, Hashable {
        let stepName: String
        let stepIndex: Int
        let timerEnd: Date
        let isPaused: Bool
    }
}
