import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

// Same accent the highlighted card surface uses in the app.
private let accent = Color(red: 1.0, green: 0.35, blue: 0.10)

struct TimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .activityBackgroundTint(.black.opacity(0.55))
                .activitySystemActionForegroundColor(accent)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .font(.title2)
                        .foregroundStyle(accent)
                }
                DynamicIslandExpandedRegion(.center) {
                    CountdownText(state: context.state)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isRinging {
                        StopButton()
                    }
                }
            } compactLeading: {
                Image(systemName: "timer").foregroundStyle(accent)
            } compactTrailing: {
                CountdownText(state: context.state)
                    .frame(maxWidth: 54)
                    .foregroundStyle(accent)
            } minimal: {
                Image(systemName: "timer").foregroundStyle(accent)
            }
        }
    }
}

// MARK: - Lock screen

private struct LockScreenView: View {
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: state.isRinging ? "bell.fill" : "timer")
                .font(.title)
                .foregroundStyle(accent)

            VStack(alignment: .leading, spacing: 2) {
                // Spelled out rather than a ternary: `Text(cond ? "a" : "b")` binds to the
                // `String` overload and would ship untranslated.
                Group {
                    if state.isRinging {
                        Text("Timer finished")
                    } else {
                        Text("Timer")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                CountdownText(state: state)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
            }

            Spacer(minLength: 0)

            if state.isRinging {
                StopButton()
            }
        }
        .padding(16)
    }
}

// MARK: - Pieces

// `Text(timerInterval:)` redraws itself once a second without the app being awake, so the
// countdown stays live on the lock screen with no per-second activity updates.
private struct CountdownText: View {
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        if state.isRinging {
            Text(verbatim: "00:00")
                .monospacedDigit()
        } else if let paused = state.pausedRemaining {
            Text(
                Duration.seconds(Int(max(0, paused.rounded(.up))))
                    .formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
            )
            .monospacedDigit()
            .foregroundStyle(.secondary)
        } else {
            Text(timerInterval: Date()...state.endDate, countsDown: true)
                .monospacedDigit()
        }
    }
}

private struct StopButton: View {
    var body: some View {
        Button(intent: StopTimerIntent()) {
            Text("Stop")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(accent)
    }
}
