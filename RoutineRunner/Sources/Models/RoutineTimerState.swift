import Foundation

/// Single source of truth for the running routine timer.
/// Persisted to App Group UserDefaults so both the app and the
/// widget extension stay in sync.
struct RoutineTimerState: Codable {
    let routineTitle: String
    let totalSteps: Int
    let stepName: String
    let stepIndex: Int
    /// Wall-clock date when the current step reaches zero.
    /// Both the app UI and the Live Activity derive "remaining" from this.
    let stepEndDate: Date
    let isPaused: Bool
    /// Snapshot of remaining seconds at the moment of last write.
    /// Used only when paused (stepEndDate is meaningless while paused).
    let remainingSeconds: Int

    /// All step names, so the widget intent can look up the next step.
    let stepNames: [String]
    /// All step durations, so the widget intent can set the next step's timer.
    let stepDurations: [TimeInterval]

    // MARK: - Persistence

    private static let suiteName = "group.com.personal.RoutineRunner"
    private static let key = "activeTimerState"

    static var shared: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    func save() {
        guard let defaults = Self.shared,
              let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.key)
    }

    static func load() -> RoutineTimerState? {
        guard let defaults = shared,
              let data = defaults.data(forKey: key),
              let state = try? JSONDecoder().decode(RoutineTimerState.self, from: data) else { return nil }
        return state
    }

    static func clear() {
        shared?.removeObject(forKey: key)
    }

    // MARK: - Derived

    /// Compute remaining seconds from stepEndDate right now.
    var currentRemainingSeconds: TimeInterval {
        if isPaused {
            return TimeInterval(remainingSeconds)
        }
        return max(0, stepEndDate.timeIntervalSinceNow)
    }
}
