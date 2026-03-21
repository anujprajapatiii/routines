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
                HStack(spacing: 24) {
                    Label("\(routine.steps.count) steps", systemImage: "list.number")
                    Spacer()
                    Label(formatDuration(routine.totalDuration), systemImage: "clock")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
            }

            Section {
                ForEach(Array(routine.steps.enumerated()), id: \.element.id) { index, step in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(index + 1).")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .monospacedDigit()
                            Text(step.title)
                                .font(.body.weight(.medium))
                            Spacer()
                            Text(formatDuration(step.duration))
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.secondary.opacity(0.1), in: Capsule())
                        }

                        if !step.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(step.notes.indices, id: \.self) { i in
                                    noteView(step.notes[i])
                                }
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 28)
                        }
                    }
                    .padding(.vertical, 6)
                }
            } header: {
                Text("Steps")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(routine.title)
        .safeAreaInset(edge: .bottom) {
            Button {
                showPlayer = true
            } label: {
                Text("Start Routine")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
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
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.caption)
                    Text(note.text)
                }
            }
        } else {
            HStack(alignment: .top, spacing: 6) {
                Text("•")
                    .foregroundStyle(.tertiary)
                Text(note.text)
            }
        }
    }
}
