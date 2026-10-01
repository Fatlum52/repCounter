import Foundation

#if os(iOS)
import ActivityKit
import AlarmKit
import SwiftUI

// The iOS timer is an AlarmKit alarm: the system counts it down, rings it through silent
// mode and Focus, and shows the Live Activity — the app process does not need to be alive.
// Shared by the app and the widget extension. The widget's buttons are `LiveActivityIntent`s,
// which run in the app process, so every caller reads and writes the same snapshot.
// `nonisolated` opts out of the app target's default MainActor isolation: intents and
// ActivityKit use these off the main actor.

nonisolated struct TimerMetadata: AlarmMetadata {}

// AlarmKit reports *that* a timer counts down or is paused, not how much is left, so the
// anchors live here. Persisted, so a relaunch mid-countdown picks the timer back up.
nonisolated struct TimerSnapshot: Codable, Equatable {
    var alarmID: UUID
    var totalDuration: TimeInterval
    // Exactly one of these is set: `endDate` while running, `pausedRemaining` while paused.
    var endDate: Date?
    var pausedRemaining: TimeInterval?

    func remaining(at now: Date = .now) -> TimeInterval {
        if let pausedRemaining { return pausedRemaining }
        guard let endDate else { return 0 }
        return max(0, endDate.timeIntervalSince(now))
    }
}

nonisolated enum TimerAlarm {

    // Same accent the highlighted card surface uses in the app.
    static let accent = Color(red: 1.0, green: 0.35, blue: 0.10)

    private static let snapshotKey = "timer.alarmSnapshot"

    static var snapshot: TimerSnapshot? {
        get {
            guard let data = UserDefaults.standard.data(forKey: snapshotKey) else { return nil }
            return try? JSONDecoder().decode(TimerSnapshot.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: snapshotKey)
            } else {
                UserDefaults.standard.removeObject(forKey: snapshotKey)
            }
        }
    }

    // MARK: - Authorization

    // Asked on the first start rather than at launch, so the prompt has context.
    static func requestAuthorization() async -> Bool {
        switch AlarmManager.shared.authorizationState {
        case .authorized: return true
        case .denied: return false
        case .notDetermined: break
        @unknown default: break
        }
        return (try? await AlarmManager.shared.requestAuthorization()) == .authorized
    }

    // MARK: - Lifecycle

    // One timer at a time: anything still scheduled or ringing is cleared first.
    static func start(duration: TimeInterval) async throws -> TimerSnapshot {
        for alarm in (try? AlarmManager.shared.alarms) ?? [] {
            discard(alarm)
        }
        snapshot = nil

        let id = UUID()
        let begin = Date.now
        let attributes = AlarmAttributes<TimerMetadata>(
            presentation: presentation,
            metadata: TimerMetadata(),
            tintColor: accent
        )
        _ = try await AlarmManager.shared.schedule(
            id: id,
            configuration: .timer(duration: duration, attributes: attributes, sound: .named("AlarmLoop.wav"))
        )

        let started = TimerSnapshot(alarmID: id, totalDuration: duration, endDate: begin.addingTimeInterval(duration))
        snapshot = started
        return started
    }

    // The snapshot is written before AlarmKit is told, so the `alarmUpdates` this triggers
    // already finds the new anchor; it is rolled back if AlarmKit refuses.
    static func pause(id: UUID) throws {
        try update(id: id, { snapshot in
            snapshot.pausedRemaining = snapshot.remaining()
            snapshot.endDate = nil
        }, apply: { try AlarmManager.shared.pause(id: id) })
    }

    static func resume(id: UUID) throws {
        try update(id: id, { snapshot in
            snapshot.endDate = Date.now.addingTimeInterval(snapshot.remaining())
            snapshot.pausedRemaining = nil
        }, apply: { try AlarmManager.shared.resume(id: id) })
    }

    // Removes a countdown that has not rung yet.
    static func cancel(id: UUID) throws {
        try AlarmManager.shared.cancel(id: id)
        clearSnapshot(for: id)
    }

    // Silences a ringing timer.
    static func stop(id: UUID) throws {
        try AlarmManager.shared.stop(id: id)
        clearSnapshot(for: id)
    }

    static func discard(_ alarm: Alarm) {
        if alarm.state == .alerting {
            try? stop(id: alarm.id)
        } else {
            try? cancel(id: alarm.id)
        }
    }

    // MARK: - Internals

    private static func update(
        id: UUID,
        _ change: (inout TimerSnapshot) -> Void,
        apply: () throws -> Void
    ) throws {
        let previous = snapshot
        if var changed = previous, changed.alarmID == id {
            change(&changed)
            snapshot = changed
        }
        do {
            try apply()
        } catch {
            snapshot = previous
            throw error
        }
    }

    private static func clearSnapshot(for id: UUID) {
        if snapshot?.alarmID == id { snapshot = nil }
    }

    private static var presentation: AlarmPresentation {
        AlarmPresentation(
            alert: alert,
            countdown: AlarmPresentation.Countdown(
                title: "Timer",
                pauseButton: AlarmButton(
                    text: "Pause",
                    textColor: accent,
                    systemImageName: "pause.fill"
                )
            ),
            paused: AlarmPresentation.Paused(
                title: "Paused",
                resumeButton: AlarmButton(
                    text: "Resume",
                    textColor: accent,
                    systemImageName: "play.fill"
                )
            )
        )
    }

    // iOS 26.1 draws its own Stop button and ignores a custom one; 26.0 still needs it.
    private static var alert: AlarmPresentation.Alert {
        let title: LocalizedStringResource = "Timer finished"
        if #available(iOS 26.1, *) {
            return AlarmPresentation.Alert(title: title)
        }
        return AlarmPresentation.Alert(
            title: title,
            stopButton: AlarmButton(
                text: "Stop",
                textColor: .white,
                systemImageName: "stop.fill"
            )
        )
    }
}
#endif
