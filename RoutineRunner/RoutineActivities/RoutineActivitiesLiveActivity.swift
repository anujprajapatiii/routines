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
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.routineTitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Label("Step \(context.state.stepIndex + 1)/\(context.attributes.totalSteps)",
                              systemImage: "list.number")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    liveTimer(context: context)
                        .font(.title3.monospacedDigit().bold())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        Text(context.state.stepName)
                            .font(.headline)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ProgressView(
                            value: Double(context.state.stepIndex),
                            total: Double(max(context.attributes.totalSteps, 1))
                        )
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
                liveTimer(context: context)
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
        VStack(spacing: 12) {
            // Top row: routine title + timer
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.routineTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(context.state.stepName)
                        .font(.title3.weight(.semibold))
                        .lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    liveTimer(context: context)
                        .font(.title2.monospacedDigit().bold())
                    if context.state.isPaused {
                        Text("PAUSED")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                    } else {
                        Text("remaining")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Bottom row: progress bar + step counter
            HStack(spacing: 8) {
                ProgressView(
                    value: Double(context.state.stepIndex),
                    total: Double(max(context.attributes.totalSteps, 1))
                )
                .tint(.accentColor)

                Text("\(context.state.stepIndex + 1)/\(context.attributes.totalSteps)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Live Timer

    @ViewBuilder
    private func liveTimer(context: ActivityViewContext<RoutineActivityAttributes>) -> some View {
        if context.state.isPaused {
            // When paused, show a frozen static time
            Text(timeString(context.state.remainingSeconds))
                .foregroundStyle(.secondary)
        } else {
            // When running, use the system live countdown
            Text(timerInterval: Date()...context.state.stepEndDate, countsDown: true)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Helpers

    private func timeString(_ seconds: Int) -> String {
        let m = max(0, seconds) / 60
        let s = max(0, seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}
