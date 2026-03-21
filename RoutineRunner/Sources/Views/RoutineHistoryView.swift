import SwiftUI

struct RoutineHistoryView: View {
    @EnvironmentObject private var historyStore: RoutineHistoryStore
    @Environment(\.dismiss) private var dismiss
    @State private var displayedMonth = Date()
    @State private var showClearConfirmation = false
    @State private var selectedRoutine: String? // fileName filter, nil = all

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            List {
                // Per-routine streak cards
                if !historyStore.records.isEmpty {
                    Section {
                        ForEach(routineSummaries, id: \.fileName) { summary in
                            routineStreakRow(summary)
                        }
                    } header: {
                        Text("Streaks")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .textCase(nil)
                    }
                }

                // Calendar
                Section {
                    // Filter picker
                    if routineSummaries.count > 1 {
                        Picker("Routine", selection: $selectedRoutine) {
                            Text("All Routines").tag(nil as String?)
                            ForEach(routineSummaries, id: \.fileName) { summary in
                                Text(summary.title).tag(summary.fileName as String?)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    calendarGrid
                } header: {
                    calendarHeader
                }

                // Recent completions
                Section {
                    if filteredCompletions.isEmpty {
                        Text("No completions yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredCompletions) { record in
                            completionRow(record)
                        }
                    }
                } header: {
                    Text("Recent")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }

                if !historyStore.records.isEmpty {
                    Section {
                        Button("Clear All History", role: .destructive) {
                            showClearConfirmation = true
                        }
                    }
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
            .confirmationDialog("Clear all completion history?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
                Button("Clear All", role: .destructive) {
                    historyStore.clearAll()
                }
            } message: {
                Text("This will permanently delete all completion records and reset your streaks.")
            }
        }
    }

    // MARK: - Per-Routine Summaries

    private struct RoutineSummary {
        let fileName: String
        let title: String
        let currentStreak: Int
        let bestStreak: Int
        let total: Int
    }

    private var routineSummaries: [RoutineSummary] {
        historyStore.trackedRoutineFileNames
            .map { fileName in
                RoutineSummary(
                    fileName: fileName,
                    title: historyStore.latestTitle(for: fileName),
                    currentStreak: historyStore.currentStreak(for: fileName),
                    bestStreak: historyStore.longestStreak(for: fileName),
                    total: historyStore.totalCompletions(for: fileName)
                )
            }
            .sorted { $0.currentStreak > $1.currentStreak }
    }

    private func routineStreakRow(_ summary: RoutineSummary) -> some View {
        HStack(spacing: 12) {
            // Streak flame
            VStack(spacing: 2) {
                Text("\(summary.currentStreak)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(summary.currentStreak > 0 ? .orange : .secondary)
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .foregroundStyle(summary.currentStreak > 0 ? .orange : .secondary.opacity(0.4))
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(summary.title)
                    .font(.body.weight(.medium))
                HStack(spacing: 12) {
                    Label("\(summary.total) total", systemImage: "checkmark.circle")
                    Label("Best: \(summary.bestStreak)", systemImage: "trophy")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
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
        let completionDays: Set<DateComponents>
        if let fileName = selectedRoutine {
            completionDays = historyStore.completionDays(for: fileName)
        } else {
            completionDays = historyStore.allCompletionDays()
        }
        let today = calendar.dateComponents([.year, .month, .day], from: Date())

        return VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(days, id: \.self) { components in
                    if components.day == nil {
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

    private var filteredCompletions: [CompletionRecord] {
        let source: [CompletionRecord]
        if let fileName = selectedRoutine {
            source = historyStore.completions(for: fileName)
        } else {
            source = historyStore.records.sorted { $0.date > $1.date }
        }
        return Array(source.prefix(20))
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

    private func daysInMonth() -> [DateComponents] {
        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstOfMonth = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return [] }

        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        let leadingBlanks = weekdayOfFirst - 1

        var cells: [DateComponents] = []
        for _ in 0..<leadingBlanks {
            cells.append(DateComponents())
        }
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
