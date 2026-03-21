import SwiftUI

struct RoutineHistoryView: View {
    @EnvironmentObject private var historyStore: RoutineHistoryStore
    @Environment(\.dismiss) private var dismiss
    @State private var displayedMonth = Date()

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statsRow
                }

                Section {
                    calendarGrid
                } header: {
                    calendarHeader
                }

                Section {
                    if recentCompletions.isEmpty {
                        Text("No completions yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recentCompletions) { record in
                            completionRow(record)
                        }
                    }
                } header: {
                    Text("Recent")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack {
            statItem(value: historyStore.currentStreak(), label: "Current Streak")
            Spacer()
            statItem(value: historyStore.longestStreak(), label: "Best Streak")
            Spacer()
            statItem(value: historyStore.totalCompletions, label: "Total")
        }
        .padding(.vertical, 4)
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.weight(.bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Calendar

    private var calendarHeader: some View {
        HStack {
            Button { shiftMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(monthYearString)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            Button { shiftMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.plain)
        }
        .textCase(nil)
    }

    private var calendarGrid: some View {
        let days = daysInMonth()
        let completionDays = historyStore.allCompletionDays()
        let today = calendar.dateComponents([.year, .month, .day], from: Date())

        return VStack(spacing: 6) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(days, id: \.self) { components in
                    if components.day == nil {
                        // Empty cell for padding
                        Text("")
                            .frame(height: 32)
                    } else {
                        let isCompleted = completionDays.contains(components)
                        let isToday = components == today
                        Text("\(components.day!)")
                            .font(.caption.weight(isToday ? .bold : .regular))
                            .foregroundStyle(isCompleted ? .white : (isToday ? .primary : .secondary))
                            .frame(width: 32, height: 32)
                            .background {
                                if isCompleted {
                                    Circle().fill(Color.accentColor)
                                } else if isToday {
                                    Circle().strokeBorder(Color.accentColor, lineWidth: 1.5)
                                }
                            }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Recent Completions

    private var recentCompletions: [CompletionRecord] {
        historyStore.records.sorted { $0.date > $1.date }.prefix(20).map { $0 }
    }

    private func completionRow(_ record: CompletionRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.routineTitle)
                    .font(.body.weight(.medium))
                Text(record.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(record.elapsedSeconds))
                    .font(.subheadline.monospacedDigit())
                let diff = record.elapsedSeconds - record.expectedSeconds
                if abs(diff) >= 10 {
                    Text(diff > 0 ? "+\(formatDuration(diff))" : "-\(formatDuration(abs(diff)))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(diff > 0 ? .orange : .green)
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Helpers

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func shiftMonth(_ delta: Int) {
        if let newDate = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = newDate
        }
    }

    /// Returns DateComponents for each cell in the month grid.
    /// Leading empty cells have day == nil.
    private func daysInMonth() -> [DateComponents] {
        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstOfMonth = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return [] }

        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth) // 1 = Sunday
        let leadingBlanks = weekdayOfFirst - 1

        var cells: [DateComponents] = []
        // Leading blanks
        for _ in 0..<leadingBlanks {
            cells.append(DateComponents())
        }
        // Actual days
        for day in range {
            var dc = comps
            dc.day = day
            cells.append(dc)
        }
        return cells
    }
}

#Preview {
    RoutineHistoryView()
        .environmentObject(RoutineHistoryStore.preview)
}
