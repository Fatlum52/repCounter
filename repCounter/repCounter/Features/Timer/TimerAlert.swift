import Foundation
import UserNotifications

#if os(iOS)
import AudioToolbox
#elseif os(macOS)
import AppKit
#endif

// The "time is up" signal. A suspended app runs no code, so a notification is scheduled up
// front; if we are on screen at zero we play the sound directly and drop that notification.
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

    // Authorization is requested on first use, not at launch, so the prompt has context.
    static func schedule(at endDate: Date) {
        Task {
            let center = UNUserNotificationCenter.current()
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return }

            // Re-read: the permission prompt may have eaten some of the original duration.
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
