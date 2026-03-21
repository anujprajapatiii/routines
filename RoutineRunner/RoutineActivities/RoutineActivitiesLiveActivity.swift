import ActivityKit
import SwiftUI
import WidgetKit

struct RoutineActivitiesLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RoutineActivityAttributes.self) { context in
            // MARK: - Lock Screen / StandBy banner
            lockScreenView(context: context)
                .activityBackgroundTint(.black.opacity(0.75))
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
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.stepName)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        if context.state.isPaused {
                            Text("PAUSED")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)
                        }

                        ProgressView(
                            value: Double(context.state.stepIndex),
                            total: Double(max(context.attributes.totalSteps, 1))
                        )
                        .tint(.cyan)
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // MARK: - Compact Leading
                Text(context.state.stepName)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
            } compactTrailing: {
                // MARK: - Compact Trailing
                liveTimer(context: context)
                    .font(.caption.monospacedDigit().bold())
            } minimal: {
                // MARK: - Minimal
                liveTimer(context: context)
                    .font(.caption2.monospacedDigit())
            }
        }
    }

    // MARK: - Lock Screen Layout

    private func lockScreenView(context: ActivityViewContext<RoutineActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            // Top row: routine title + step counter
            HStack {
                Text(context.attributes.routineTitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("Step \(context.state.stepIndex + 1) of \(context.attributes.totalSteps)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Middle row: step name + live timer
            HStack(alignment: .center) {
                Text(context.state.stepName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 2) {
                    liveTimer(context: context)
                        .font(.title.monospacedDigit().bold())
                        .foregroundStyle(.white)
                    if context.state.isPaused {
                        Text("PAUSED")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.orange)
                    } else {
                        Text("remaining")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }

            // Bottom row: progress bar
            ProgressView(
                value: Double(context.state.stepIndex),
                total: Double(max(context.attributes.totalSteps, 1))
            )
            .tint(.cyan)
        }
        .padding(16)
    }

    // MARK: - Live Timer

    @ViewBuilder
    private func liveTimer(context: ActivityViewContext<RoutineActivityAttributes>) -> some View {
        if context.state.isPaused {
            Text(timeString(context.state.remainingSeconds))
                .foregroundStyle(.secondary)
        } else {
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
