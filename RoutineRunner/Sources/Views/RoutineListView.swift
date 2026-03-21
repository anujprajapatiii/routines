import SwiftUI

struct RoutineListView: View {
    @EnvironmentObject private var store: RoutineStore
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showSettings = false
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
        List(store.routines) { routine in
            NavigationLink(destination: RoutineDetailView(routine: routine)) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.title)
                            .font(.headline)
                        HStack(spacing: 12) {
                            Label("\(routine.steps.count) steps", systemImage: "list.number")
                            Label(formatDuration(routine.totalDuration), systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        selectedRoutineForPlayer = routine
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.tint)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
            }
        }
        .fullScreenCover(item: $selectedRoutineForPlayer) { routine in
            RoutinePlayerView(routine: routine, routineCompleted: $routineCompleted, hapticsEnabled: store.settings.hapticsEnabled)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Routines")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Configure a GitHub repo in Settings\nand sync to load your routines.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Settings") { showSettings = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
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

#Preview {
    RoutineListView()
        .environmentObject(RoutineStore())
}
