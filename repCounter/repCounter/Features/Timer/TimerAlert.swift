import Foundation
import UserNotifications

#if os(iOS)
import AudioToolbox
#elseif os(macOS)
import AppKit
#endif

/// The "your time is up" signal, in two halves.
///
/// Which half fires depends on where the app is when the countdown ends: a suspended
/// app runs no code at all, so the only way to make noise then is a local notification
/// scheduled up front. When the app *is* on screen we play the sound directly and drop
/// the pending notification, so the user never hears both.
enum TimerAlert {

    private static let requestID = "repCounter.timer.finished"

    // MARK: - Foreground

    static func playNow() {
        #if os(iOS)
        AudioServicesPlayAlertSound(SystemSoundID(1005))
        #elseif os(macOS)
        NSSound.beep()
        #endif
    }

    // MARK: - Background

    /// Schedules the alert for `endDate`. Authorization is requested here, on first
    /// use, rather than at launch — the prompt only makes sense once the user has
    /// actually started a timer.
    static func schedule(at endDate: Date) {
        Task {
            let center = UNUserNotificationCenter.current()
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return }

            // Re-read the remaining time: the permission prompt may have sat on
            // screen for a while, so the original duration is no longer accurate.
            let interval = endDate.timeIntervalSinceNow
            guard interval > 0 else { return }

            let content = UNMutableNotificationContent()
            content.title = String(localized: "Timer finished")
            content.body = String(localized: "Your time is up.")
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: requestID,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            )

            center.removePendingNotificationRequests(withIdentifiers: [requestID])
            try? await center.add(request)
        }
    }

    static func cancelScheduled() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestID])
        center.removeDeliveredNotifications(withIdentifiers: [requestID])
    }
}
