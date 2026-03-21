import ActivityKit
import WidgetKit
import SwiftUI

struct RoutineActivitiesLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RoutineActivityAttributes.self) { context in
            // MARK: - Lock Screen / Banner
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.routineTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        Text(context.state.stepName)
                            .font(.headline)
                            .lineLimit(1)
                        timerText(state: context.state)
                            .font(.title2.monospacedDigit())
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.stepIndex + 1)/\(context.attributes.totalSteps)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(
                        value: Double(context.state.stepIndex),
                        total: Double(context.attributes.totalSteps)
                    )
                    .tint(.blue)
                }
            } compactLeading: {
                Text("\(context.state.stepIndex + 1)/\(context.attributes.totalSteps)")
                    .font(.caption2.monospacedDigit())
            } compactTrailing: {
                timerText(state: context.state)
                    .font(.caption2.monospacedDigit())
            } minimal: {
                timerText(state: context.state)
                    .font(.caption2.monospacedDigit())
            }
        }
    }

    // MARK: - Lock Screen

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<RoutineActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.routineTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(context.state.stepName)
                        .font(.headline)
                        .lineLimit(1)
                }
                Spacer()
                timerText(state: context.state)
                    .font(.title.monospacedDigit())
            }
            HStack {
                Text("Step \(context.state.stepIndex + 1) of \(context.attributes.totalSteps)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if context.state.isPaused {
                    Label("Paused", systemImage: "pause.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ProgressView(
                value: Double(context.state.stepIndex),
                total: Double(context.attributes.totalSteps)
            )
            .tint(.blue)
        }
        .padding()
    }

    // MARK: - Timer Helper

    @ViewBuilder
    private func timerText(state: RoutineActivityAttributes.ContentState) -> some View {
        if state.isPaused {
            Text(state.timerEnd, style: .timer)
        } else {
            Text(timerInterval: Date()...state.timerEnd, countsDown: true)
        }
    }
}
