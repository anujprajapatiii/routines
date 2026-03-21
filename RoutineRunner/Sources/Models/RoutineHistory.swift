import Foundation

/// A single recorded completion of a routine.
struct CompletionRecord: Codable, Identifiable {
    let id: UUID
    let routineFileName: String
    let routineTitle: String
    let date: Date
    let elapsedSeconds: TimeInterval
    let expectedSeconds: TimeInterval

    init(
        id: UUID = UUID(),
        routineFileName: String,
        routineTitle: String,
        date: Date = Date(),
        elapsedSeconds: TimeInterval,
        expectedSeconds: TimeInterval
    ) {
        self.id = id
        self.routineFileName = routineFileName
        self.routineTitle = routineTitle
        self.date = date
        self.elapsedSeconds = elapsedSeconds
        self.expectedSeconds = expectedSeconds
    }
}

/// Manages persistence and queries for routine completion history.
@MainActor
final class RoutineHistoryStore: ObservableObject {
    @Published private(set) var records: [CompletionRecord] = []

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("routine_history.json")
    }

    init() {
        load()
    }

    func record(_ completion: CompletionRecord) {
        records.append(completion)
        save()
    }

    // MARK: - Queries

    /// All completions for a specific routine, newest first.
    func completions(for fileName: String) -> [CompletionRecord] {
        records
            .filter { $0.routineFileName == fileName }
            .sorted { $0.date > $1.date }
    }

    /// Dates (day-only) on which a specific routine was completed.
    func completionDays(for fileName: String) -> Set<DateComponents> {
        let cal = Calendar.current
        return Set(
            completions(for: fileName)
                .map { cal.dateComponents([.year, .month, .day], from: $0.date) }
        )
    }

    /// Dates (day-only) on which any routine was completed.
    func allCompletionDays() -> Set<DateComponents> {
        let cal = Calendar.current
        return Set(
            records.map { cal.dateComponents([.year, .month, .day], from: $0.date) }
        )
    }

    /// Current streak: consecutive days ending today (or yesterday) with at least one completion.
    func currentStreak() -> Int {
        streak(from: Date())
    }

    /// Longest streak ever recorded.
    func longestStreak() -> Int {
        guard !records.isEmpty else { return 0 }
        let cal = Calendar.current
        let sortedDays = allCompletionDays()
            .compactMap { cal.date(from: $0) }
            .sorted()

        guard !sortedDays.isEmpty else { return 0 }

        var best = 1
        var current = 1
        for i in 1..<sortedDays.count {
            if cal.isDate(sortedDays[i], inSameDayAs: sortedDays[i - 1]) {
                continue
            } else if let expected = cal.date(byAdding: .day, value: 1, to: sortedDays[i - 1]),
                      cal.isDate(sortedDays[i], inSameDayAs: expected) {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }

    /// Total number of completions.
    var totalCompletions: Int { records.count }

    // MARK: - Private

    private func streak(from date: Date) -> Int {
        let cal = Calendar.current
        let days = allCompletionDays()

        var check = cal.dateComponents([.year, .month, .day], from: date)
        // If today doesn't have a completion, start from yesterday
        if !days.contains(check) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: date) else { return 0 }
            check = cal.dateComponents([.year, .month, .day], from: yesterday)
            if !days.contains(check) { return 0 }
        }

        var count = 0
        while days.contains(check) {
            count += 1
            guard let prev = cal.date(from: check),
                  let dayBefore = cal.date(byAdding: .day, value: -1, to: prev) else { break }
            check = cal.dateComponents([.year, .month, .day], from: dayBefore)
        }
        return count
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([CompletionRecord].self, from: data) else { return }
        records = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Pre-populated store for previews.
    static var preview: RoutineHistoryStore {
        let store = RoutineHistoryStore()
        let cal = Calendar.current
        for daysAgo in 0..<7 {
            store.records.append(CompletionRecord(
                routineFileName: "morning.md",
                routineTitle: "Morning Routine",
                date: cal.date(byAdding: .day, value: -daysAgo, to: Date())!,
                elapsedSeconds: 780 + Double(daysAgo * 15),
                expectedSeconds: 780
            ))
        }
        return store
    }
}
