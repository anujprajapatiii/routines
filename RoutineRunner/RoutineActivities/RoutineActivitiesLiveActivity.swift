import ActivityKit
import SwiftUI
import WidgetKit

struct RoutineActivitiesLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RoutineActivityAttributes.self) { context in
            // MARK: - Lock Screen / Banner
            // This is also rendered as the home-screen bar on iOS 26+
            HStack(spacing: 10) {
                // Green live indicator
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)

                // Step name + step counter
                VStack(alignment: .leading, spacing: 1) {
                    Text(context.state.stepName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(context.attributes.routineTitle) · Step \(context.state.stepIndex + 1)/\(context.attributes.totalSteps)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                // Live timer
                if context.state.isPaused {
                    Text(timeString(context.state.remainingSeconds))
                        .font(.subheadline.monospacedDigit().bold())
                        .foregroundStyle(.white.opacity(0.5))
                } else {
                    Text(timerInterval: Date()...context.state.stepEndDate, countsDown: true)
                        .font(.subheadline.monospacedDigit().bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .activityBackgroundTint(.black.opacity(0.6))
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded (long-press)
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.routineTitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                            Text("Step \(context.state.stepIndex + 1)/\(context.attributes.totalSteps)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        if context.state.isPaused {
                            Text(timeString(context.state.remainingSeconds))
                                .font(.title3.monospacedDigit().bold())
                                .foregroundStyle(.secondary)
                            Text("PAUSED")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.orange)
                        } else {
                            Text(timerInterval: Date()...context.state.stepEndDate, countsDown: true)
                                .font(.title3.monospacedDigit().bold())
                                .multilineTextAlignment(.trailing)
                            Text("remaining")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.stepName)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(
                        value: Double(context.state.stepIndex),
                        total: Double(max(context.attributes.totalSteps, 1))
                    )
                    .tint(.cyan)
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
                }
            } compactLeading: {
                // MARK: - Compact Leading
                HStack(spacing: 5) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text(context.state.stepName)
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                }
            } compactTrailing: {
                // MARK: - Compact Trailing
                if context.state.isPaused {
                    Text(timeString(context.state.remainingSeconds))
                        .font(.caption2.monospacedDigit().bold())
                        .foregroundStyle(.secondary)
                } else {
                    Text(timerInterval: Date()...context.state.stepEndDate, countsDown: true)
                        .font(.caption2.monospacedDigit().bold())
                        .multilineTextAlignment(.trailing)
                }
            } minimal: {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Helpers

    private func timeString(_ seconds: Int) -> String {
        let m = max(0, seconds) / 60
        let s = max(0, seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}
