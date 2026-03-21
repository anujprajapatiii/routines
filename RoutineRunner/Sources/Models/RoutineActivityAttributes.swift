import ActivityKit
import Foundation

struct RoutineActivityAttributes: ActivityAttributes {
    let routineTitle: String
    let totalSteps: Int

    struct ContentState: Codable, Hashable {
        let stepName: String
        let stepIndex: Int
        let remainingSeconds: Int
        let isPaused: Bool
    }
}
