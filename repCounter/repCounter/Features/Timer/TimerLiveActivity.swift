import Foundation

#if os(iOS)
import ActivityKit

// Drives the lock screen countdown. Every call is best-effort: Live Activities can be
// switched off system-wide, and the timer has to keep working when they are.
@MainActor
enum TimerLiveActivity {

    private static var activity: Activity<TimerActivityAttributes>?

    static func start(endDate: Date) {
        end()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = TimerActivityAttributes.ContentState(
            endDate: endDate,
            pausedRemaining: nil,
            isRinging: false
        )

        activity = try? Activity.request(
            attributes: TimerActivityAttributes(startDate: Date()),
            content: ActivityContent(state: state, staleDate: nil)
        )
    }

    static func update(endDate: Date, pausedRemaining: TimeInterval? = nil, isRinging: Bool = false) {
        guard let activity else { return }
        let state = TimerActivityAttributes.ContentState(
            endDate: endDate,
            pausedRemaining: pausedRemaining,
            isRinging: isRinging
        )
        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    static func end() {
        guard let activity else { return }
        self.activity = nil
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }
}
#endif
