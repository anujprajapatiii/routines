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
            ScrollView {
                if store.routines.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(store.routines) { routine in
                            routineCard(routine)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(.systemGroupedBackground))
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
                await store.sync(historyStore: historyStore)
            }
            .task {
                if store.settings.isConfigured && store.settings.autoSyncOnLaunch {
                    await store.sync(historyStore: historyStore)
                }
            }
            .fullScreenCover(item: $selectedRoutineForPlayer) { routine in
                RoutinePlayerView(routine: routine, routineCompleted: $routineCompleted, hapticsEnabled: store.settings.hapticsEnabled) { record in
                    historyStore.record(record)
                }
            }
        }
    }

    // MARK: - Routine Card

    private func routineCard(_ routine: Routine) -> some View {
        let streak = historyStore.currentStreak(for: routine.fileName)
        let total = historyStore.totalCompletions(for: routine.fileName)

        return NavigationLink(destination: RoutineDetailView(routine: routine)) {
            VStack(spacing: 0) {
                // Top section: title + play
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(routine.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Text("\(routine.steps.count) steps · \(formatDuration(routine.totalDuration))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    Button {
                        selectedRoutineForPlayer = routine
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.accentColor, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Bottom section: streak + stats
                HStack(spacing: 0) {
                    // Streak
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.subheadline)
                            .foregroundStyle(streak > 0 ? .orange : .secondary.opacity(0.3))
                        Text(streak > 0 ? "\(streak) day streak" : "No streak")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(streak > 0 ? .primary : .secondary)
                    }

                    Spacer()

                    // Total completions
                    if total > 0 {
                        Text("\(total) completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground).opacity(0.5))
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

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
