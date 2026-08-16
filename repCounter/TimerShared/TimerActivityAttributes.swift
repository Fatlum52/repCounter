import Foundation

#if os(iOS)
import ActivityKit

// Shared by the app (which starts and ends the activity) and the widget extension
// (which renders it), so both sides agree on the payload.
struct TimerActivityAttributes: ActivityAttributes {

    // The lock screen renders the countdown with `Text(timerInterval:)`, which ticks on
    // its own — so only these anchors travel, never a per-second update.
    struct ContentState: Codable, Hashable {
        var endDate: Date
        // Set while paused: a self-ticking `Text(timerInterval:)` cannot hold still, so a
        // frozen remainder is sent instead.
        var pausedRemaining: TimeInterval?
        var isRinging: Bool
    }

    var startDate: Date
}
#endif
