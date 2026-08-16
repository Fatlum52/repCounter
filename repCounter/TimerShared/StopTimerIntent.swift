import Foundation

#if os(iOS)
import AppIntents

// Backs the "Stop" button on the lock screen. As a `LiveActivityIntent` this runs inside
// the app process, so it can silence the player directly instead of round-tripping.
struct StopTimerIntent: LiveActivityIntent {

    static var title: LocalizedStringResource = "Stop"
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(name: .repCounterStopTimer, object: nil)
        }
        return .result()
    }
}
#endif

extension Notification.Name {
    static let repCounterStopTimer = Notification.Name("repCounter.timer.stop")
}
