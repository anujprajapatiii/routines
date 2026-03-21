import SwiftUI

struct RoutineListView: View {
    @EnvironmentObject private var store: RoutineStore
    @EnvironmentObject private var historyStore: RoutineHistoryStore
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var selectedRoutineForPlayer: Routine?
    @State private var routineCompleted = false

    var body: some View {
        NavigationStack {
            Group {
                if store.routines.isEmpty {
                    emptyState
                } else {
                    routinesList
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showHistory = true } label: {
                        Image(systemName: "calendar")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            isDarkMode.toggle()
                        } label: {
                            Image(systemName: isDarkMode ? "moon.fill" : "moon")
                        }
                        Button { showSettings = true } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showHistory) {
                RoutineHistoryView()
                    .environmentObject(historyStore)
            }
            .refreshable {
                await store.sync()
            }
            .task {
                if store.settings.isConfigured && store.settings.autoSyncOnLaunch {
                    await store.sync()
                }
            }
        }
    }

    private var routinesList: some View {
        List {
            if historyStore.totalCompletions > 0 {
                Section {
                    streakBanner
                }
            }
            ForEach(store.routines) { routine in
                NavigationLink(destination: RoutineDetailView(routine: routine)) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(routine.title)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            HStack(spacing: 16) {
                                Label("\(routine.steps.count) steps", systemImage: "list.number")
                                Label(formatDuration(routine.totalDuration), systemImage: "clock")
                            }
                            .font(.subheadline)
                        }
                        Spacer()
                        Button {
                            selectedRoutineForPlayer = routine
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.tint)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .fullScreenCover(item: $selectedRoutineForPlayer) { routine in
            RoutinePlayerView(routine: routine, routineCompleted: $routineCompleted, hapticsEnabled: store.settings.hapticsEnabled) { record in
                historyStore.record(record)
            }
        }
    }

    private var streakBanner: some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text("\(historyStore.currentStreak())")
                    .font(.title.weight(.bold))
                Text("streak")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 56)

            Divider()
                .frame(height: 32)

            VStack(spacing: 2) {
                Text("\(historyStore.totalCompletions)")
                    .font(.title.weight(.bold))
                Text("total")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 56)

            Divider()
                .frame(height: 32)

            VStack(spacing: 2) {
                Text("\(historyStore.longestStreak())")
                    .font(.title.weight(.bold))
                Text("best")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 56)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No Routines")
                .font(.title2.weight(.bold))
            Text("Configure a GitHub repo in Settings\nand sync to load your routines.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
            Button("Open Settings") { showSettings = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 4)
        }
        .padding(32)
    }
}

func formatDuration(_ seconds: TimeInterval) -> String {
    let totalSeconds = Int(seconds)
    let m = totalSeconds / 60
    let s = totalSeconds % 60
    if s == 0 {
        return "\(m)m"
    }
    return "\(m)m \(s)s"
}

// MARK: - Preview

private let sampleRoutine = Routine(
    title: "Morning Routine",
    steps: [
        Step(title: "Meditation", duration: 300, notes: [Note(text: "Focus on breathing")]),
        Step(title: "Stretching", duration: 600),
        Step(title: "Journaling", duration: 900, notes: [Note(text: "Write 3 gratitudes")]),
    ],
    fileName: "morning.md"
)

#Preview {
    RoutineListView()
        .environmentObject(RoutineStore.preview)
        .environmentObject(RoutineHistoryStore.preview)
}

#Preview("Detail") {
    NavigationStack {
        RoutineDetailView(routine: sampleRoutine)
            .environmentObject(RoutineStore.preview)
            .environmentObject(RoutineHistoryStore.preview)
    }
}

#Preview("Player") {
    RoutinePlayerView(routine: sampleRoutine, routineCompleted: .constant(false))
}

#Preview("Settings") {
    SettingsView()
        .environmentObject(RoutineStore.preview)
}
