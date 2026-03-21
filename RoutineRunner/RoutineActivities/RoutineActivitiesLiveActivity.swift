import ActivityKit
import SwiftUI
import WidgetKit

struct RoutineActivitiesLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RoutineActivityAttributes.self) { context in
            // MARK: - Lock Screen / StandBy banner
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded
                DynamicIslandExpandedRegion(.leading) {
                    Label("Step \(context.state.stepIndex + 1)/\(context.attributes.totalSteps)", systemImage: "list.number")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timeString(context.state.remainingSeconds))
                        .font(.title3.monospacedDigit().bold())
                        .foregroundStyle(context.state.isPaused ? .secondary : .primary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        Text(context.state.stepName)
                            .font(.headline)
                            .lineLimit(1)
                        ProgressView(value: Double(context.state.stepIndex), total: Double(context.attributes.totalSteps))
                            .tint(.white)
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // MARK: - Compact Leading
                Image(systemName: context.state.isPaused ? "pause.fill" : "timer")
                    .foregroundStyle(.secondary)
            } compactTrailing: {
                // MARK: - Compact Trailing
                Text(timeString(context.state.remainingSeconds))
                    .font(.caption.monospacedDigit().bold())
            } minimal: {
                // MARK: - Minimal
                Image(systemName: "timer")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Lock Screen Layout

    private func lockScreenView(context: ActivityViewContext<RoutineActivityAttributes>) -> some View {
        VStack(spacing: 8) {
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
                Text(timeString(context.state.remainingSeconds))
                    .font(.title2.monospacedDigit().bold())
                    .foregroundStyle(context.state.isPaused ? .secondary : .primary)
            }
            HStack {
                ProgressView(value: Double(context.state.stepIndex), total: Double(context.attributes.totalSteps))
                    .tint(.accentColor)
                Text("\(context.state.stepIndex + 1)/\(context.attributes.totalSteps)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private func timeString(_ seconds: Int) -> String {
        let m = max(0, seconds) / 60
        let s = max(0, seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}
