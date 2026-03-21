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

    /// Remove records for routines that no longer exist locally.
    func pruneOrphanedRecords(keeping activeFileNames: Set<String>) {
        let before = records.count
        records.removeAll { !activeFileNames.contains($0.routineFileName) }
        if records.count != before {
            save()
        }
    }

    /// Remove all history.
    func clearAll() {
        records.removeAll()
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

    /// Total number of completions.
    var totalCompletions: Int { records.count }

    /// Total completions for a specific routine.
    func totalCompletions(for fileName: String) -> Int {
        records.filter { $0.routineFileName == fileName }.count
    }

    /// Current streak for a specific routine.
    func currentStreak(for fileName: String) -> Int {
        streak(from: Date(), days: completionDays(for: fileName))
    }

    /// Longest streak for a specific routine.
    func longestStreak(for fileName: String) -> Int {
        bestStreak(in: completionDays(for: fileName))
    }

    /// All unique routine fileNames that have history.
    var trackedRoutineFileNames: Set<String> {
        Set(records.map(\.routineFileName))
    }

    /// Most recent title recorded for a given fileName.
    func latestTitle(for fileName: String) -> String {
        completions(for: fileName).first?.routineTitle ?? fileName
    }

    // MARK: - Private

    private func streak(from date: Date, days: Set<DateComponents>) -> Int {
        let cal = Calendar.current
        var check = cal.dateComponents([.year, .month, .day], from: date)

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

    private func bestStreak(in days: Set<DateComponents>) -> Int {
        let cal = Calendar.current
        let sorted = days.compactMap { cal.date(from: $0) }.sorted()
        guard !sorted.isEmpty else { return 0 }

        var best = 1
        var current = 1
        for i in 1..<sorted.count {
            if cal.isDate(sorted[i], inSameDayAs: sorted[i - 1]) {
                continue
            } else if let expected = cal.date(byAdding: .day, value: 1, to: sorted[i - 1]),
                      cal.isDate(sorted[i], inSameDayAs: expected) {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
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
