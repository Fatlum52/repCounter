import AVFoundation
import Foundation
import UserNotifications

// The "time is up" signal. Rings in a loop until dismissed; a silent player holds the
// audio session open during the countdown so it still sounds on a locked device.
@MainActor
enum TimerAlert {

    private static let requestID = "repCounter.timer.finished"

    private static var player: AVAudioPlayer?

    // MARK: - Audio

    // Silent playback during the countdown. Without it iOS suspends the app and nothing
    // sounds at zero; with it the process stays alive under the `audio` background mode.
    static func startKeepAlive() {
        activateSession()
        play(volume: 0)
    }

    static func startRinging() {
        activateSession()
        play(volume: 1)
    }

    static func stopAudio() {
        player?.stop()
        player = nil
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }

    private static func activateSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        // `.mixWithOthers` keeps the user's training music playing — the alarm rides on top
        // instead of killing the playlist.
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        #endif
    }

    // Reuses one looping player; changing the volume is what turns keep-alive into an alarm.
    private static func play(volume: Float) {
        if let player {
            player.volume = volume
            if !player.isPlaying { player.play() }
            return
        }

        guard let url = Bundle.main.url(forResource: "AlarmLoop", withExtension: "wav"),
              let created = try? AVAudioPlayer(contentsOf: url) else { return }

        created.numberOfLoops = -1
        created.volume = volume
        created.prepareToPlay()
        created.play()
        player = created
    }

    // MARK: - Notification fallback

    // Belt and braces: if iOS reclaims the audio session anyway, this still fires.
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
