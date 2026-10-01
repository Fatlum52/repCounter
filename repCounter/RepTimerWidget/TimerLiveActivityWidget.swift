import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

private let accent = TimerAlarm.accent

// Renders the timer's Live Activity. AlarmKit starts, updates and ends it; this only
// draws its state. The ringing alert itself (sound, system Stop) comes from the system.
struct TimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<TimerMetadata>.self) { context in
            LockScreenView(state: context.state)
                .activityBackgroundTint(.black.opacity(0.55))
                .activitySystemActionForegroundColor(accent)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.mode.symbolName)
                        .font(.title2)
                        .foregroundStyle(accent)
                }
                DynamicIslandExpandedRegion(.center) {
                    CountdownText(mode: context.state.mode)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Controls(state: context.state)
                }
            } compactLeading: {
                Image(systemName: context.state.mode.symbolName).foregroundStyle(accent)
            } compactTrailing: {
                CountdownText(mode: context.state.mode)
                    .frame(maxWidth: 54)
                    .foregroundStyle(accent)
            } minimal: {
                Image(systemName: context.state.mode.symbolName).foregroundStyle(accent)
            }
        }
    }
}

// MARK: - Lock screen

private struct LockScreenView: View {
    let state: AlarmPresentationState

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: state.mode.symbolName)
                .font(.title)
                .foregroundStyle(accent)

            VStack(alignment: .leading, spacing: 2) {
                StatusText(mode: state.mode)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                CountdownText(mode: state.mode)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
            }

            Spacer(minLength: 0)

            Controls(state: state)
        }
        .padding(16)
    }
}

// MARK: - Pieces

private extension AlarmPresentationState.Mode {
    var symbolName: String {
        switch self {
        case .alert: "bell.fill"
        default: "timer"
        }
    }
}

// Spelled out per case rather than a ternary: `Text(cond ? "a" : "b")` binds to the
// `String` overload and would ship untranslated.
private struct StatusText: View {
    let mode: AlarmPresentationState.Mode

    var body: some View {
        switch mode {
        case .alert: Text("Timer finished")
        case .paused: Text("Paused")
        default: Text("Timer")
        }
    }
}

// `Text(timerInterval:)` redraws itself once a second without the app being awake, so the
// countdown stays live with no per-second activity updates.
private struct CountdownText: View {
    let mode: AlarmPresentationState.Mode

    var body: some View {
        switch mode {
        case .countdown(let countdown):
            // Anchored to where an unpaused run would have started, so the range is never
            // empty and a resumed timer still counts to the same fire date.
            let start = countdown.fireDate.addingTimeInterval(-countdown.totalCountdownDuration)
            Text(timerInterval: start...countdown.fireDate, countsDown: true)
                .monospacedDigit()
        case .paused(let paused):
            // A self-ticking `Text(timerInterval:)` cannot hold still, so the frozen
            // remainder is formatted instead.
            let left = paused.totalCountdownDuration - paused.previouslyElapsedDuration
            Text(
                Duration.seconds(Int(max(0, left.rounded(.up))))
                    .formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
            )
            .monospacedDigit()
            .foregroundStyle(.secondary)
        default:
            Text(verbatim: "00:00")
                .monospacedDigit()
        }
    }
}

// The intents run in the app process (see `TimerIntents`), which owns the alarm.
private struct Controls: View {
    let state: AlarmPresentationState

    var body: some View {
        HStack(spacing: 10) {
            switch state.mode {
            case .countdown:
                RoundButton(intent: CancelTimerIntent(alarmID: state.alarmID), systemImage: "xmark", isProminent: false)
                    .accessibilityLabel(Text("Cancel"))
                RoundButton(intent: PauseTimerIntent(alarmID: state.alarmID), systemImage: "pause.fill", isProminent: true)
                    .accessibilityLabel(Text("Pause"))
            case .paused:
                RoundButton(intent: CancelTimerIntent(alarmID: state.alarmID), systemImage: "xmark", isProminent: false)
                    .accessibilityLabel(Text("Cancel"))
                RoundButton(intent: ResumeTimerIntent(alarmID: state.alarmID), systemImage: "play.fill", isProminent: true)
                    .accessibilityLabel(Text("Resume"))
            case .alert:
                StopButton(alarmID: state.alarmID)
            default:
                EmptyView()
            }
        }
    }
}

private struct RoundButton<Intent: AppIntent>: View {
    let intent: Intent
    let systemImage: String
    let isProminent: Bool

    var body: some View {
        Button(intent: intent) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .foregroundStyle(isProminent ? Color.white : accent)
                .background(Circle().fill(isProminent ? accent : accent.opacity(0.2)))
        }
        .buttonStyle(.plain)
    }
}

private struct StopButton: View {
    let alarmID: UUID

    var body: some View {
        Button(intent: StopTimerIntent(alarmID: alarmID)) {
            Text("Stop")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(accent)
    }
}
