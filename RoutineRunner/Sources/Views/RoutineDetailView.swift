import SwiftUI

struct RoutineDetailView: View {
    let routine: Routine
    @EnvironmentObject private var store: RoutineStore
    @Environment(\.dismiss) private var dismiss
    @State private var showPlayer = false
    @State private var routineCompleted = false

    var body: some View {
        List {
            Section {
                HStack {
                    Label("\(routine.steps.count) steps", systemImage: "list.number")
                    Spacer()
                    Label(formatDuration(routine.totalDuration), systemImage: "clock")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Section("Steps") {
                ForEach(Array(routine.steps.enumerated()), id: \.element.id) { index, step in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(index + 1).")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            Text(step.title)
                                .fontWeight(.medium)
                            Spacer()
                            Text(formatDuration(step.duration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.12), in: Capsule())
                        }

                        if !step.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(step.notes.indices, id: \.self) { i in
                                    noteView(step.notes[i])
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 24)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(routine.title)
        .safeAreaInset(edge: .bottom) {
            Button {
                showPlayer = true
            } label: {
                Text("Start Routine")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .background(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $showPlayer, onDismiss: {
            if routineCompleted {
                dismiss()
            }
        }) {
            RoutinePlayerView(routine: routine, routineCompleted: $routineCompleted, hapticsEnabled: store.settings.hapticsEnabled)
        }
    }

    @ViewBuilder
    private func noteView(_ note: Note) -> some View {
        if let link = note.link {
            Link(destination: link) {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.caption2)
                    Text(note.text)
                }
            }
        } else {
            Text("- \(note.text)")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RoutineDetailView(routine: Routine(
            title: "Morning Routine",
            steps: [
                Step(title: "Meditation", duration: 300, notes: [Note(text: "Focus on breathing")]),
                Step(title: "Stretching", duration: 600),
                Step(title: "Journaling", duration: 900, notes: [Note(text: "Write 3 gratitudes")]),
            ],
            fileName: "morning.md"
        ))
        .environmentObject(RoutineStore())
    }
}
