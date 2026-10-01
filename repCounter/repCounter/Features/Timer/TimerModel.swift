import Foundation
import SwiftUI

#if os(iOS)
import AlarmKit
#endif

// Countdown state for `TimerView`. Anchored to an absolute `endDate` rather than a
// ticking counter, so a suspended app or a dropped tick can never make it drift.
// On iOS the countdown itself is an AlarmKit alarm (see `TimerAlarm`): the phase is read
// from `alarmUpdates` and the ticker only redraws the screen while the app is in front.
// macOS counts down and rings in-process.
@MainActor
@Observable
final class TimerModel {

    // No `finished` case: at zero the countdown drops straight back to `idle` and the
    // alarm carries the news, so there is nothing to acknowledge.
    enum State {
        case idle, running, paused
    }

    // macOS starts empty since its fields are typed into; the iOS wheel opens on a
    // default because spinning away from one costs nothing.
    #if os(macOS)
    private static let defaultMinutes = 0
    #else
    private static let defaultMinutes = 2
    #endif

    // Kept separate from the running countdown so cancelling restores the last dialled duration.
    var selectedMinutes = TimerModel.defaultMinutes
    var selectedSeconds = 0

    private(set) var state: State = .idle
    private(set) var remaining: TimeInterval = 0

    // The alarm loops until silenced. Independent of `state`, which is back to `idle`.
    private(set) var isRinging = false

    private var endDate: Date?
    private var totalDuration: TimeInterval = 0
    private var ticker: Task<Void, Never>?

    #if os(iOS)
    // Set when alarms are switched off for the app — without them the timer cannot ring.
    var showsAlarmPermissionHint = false

    private var alarmID: UUID?
    // Holds back `alarmUpdates` while a start replaces the old alarm, so the gap between
    // the two cannot read as "no timer" and wipe the new one's snapshot.
    private var isStarting = false
    private var isInForeground = true

    // The loop holds `self` weakly and returns on the first update after deallocation, so
    // it needs no cancellation from `deinit` (which could not touch actor state anyway).
    init() {
        Task { [weak self] in
            for await alarms in AlarmManager.shared.alarmUpdates {
                guard let self else { return }
                self.sync(with: alarms)
            }
        }
        refresh()
    }
    #endif

    // MARK: - Derived

    var selectedDuration: TimeInterval {
        TimeInterval(selectedMinutes * 60 + selectedSeconds)
    }

    var canStart: Bool { selectedDuration > 0 }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return min(max(1 - remaining / totalDuration, 0), 1)
    }

    // `mm:ss`, rounded up so a fresh 2:00 timer reads "02:00" rather than "01:59".
    var formattedRemaining: String {
        let seconds = Int(max(0, remaining.rounded(.up)))
        return Duration.seconds(seconds)
            .formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
    }

    // MARK: - Actions

    #if os(iOS)
    func start() {
        guard canStart, !isStarting else { return }
        isStarting = true
        let duration = selectedDuration
        Task {
            defer {
                isStarting = false
                refresh()
            }
            guard await TimerAlarm.requestAuthorization() else {
                showsAlarmPermissionHint = true
                return
            }
            _ = try? await TimerAlarm.start(duration: duration)
        }
    }

    // Shown straight from the snapshot `TimerAlarm` just wrote; the `alarmUpdates` that
    // follows confirms it.
    func pause() {
        guard state == .running, let alarmID else { return }
        guard (try? TimerAlarm.pause(id: alarmID)) != nil,
              let snapshot = TimerAlarm.snapshot else { return }
        show(snapshot, as: .paused)
    }

    func resume() {
        guard state == .paused, let alarmID else { return }
        guard (try? TimerAlarm.resume(id: alarmID)) != nil,
              let snapshot = TimerAlarm.snapshot else { return }
        show(snapshot, as: .running)
    }

    func reset() {
        if let alarmID { try? TimerAlarm.cancel(id: alarmID) }
        showIdle(ringing: false)
    }

    func silence() {
        if isRinging, let alarmID { try? TimerAlarm.stop(id: alarmID) }
        isRinging = false
    }

    // Nothing counts down here in the background — AlarmKit does. Coming back re-reads
    // the alarm, since the Live Activity's buttons may have changed it meanwhile.
    func handleScenePhase(_ phase: ScenePhase) {
        isInForeground = phase == .active
        if isInForeground {
            refresh()
        } else {
            stopTicker()
        }
    }
    #else
    func start() {
        guard canStart else { return }
        silence()
        totalDuration = selectedDuration
        beginCountdown(seconds: totalDuration)
    }

    func pause() {
        guard state == .running, let endDate else { return }
        stopTicker()
        TimerAlert.cancelScheduled()
        TimerAlert.stopAudio()
        remaining = max(0, endDate.timeIntervalSinceNow)
        self.endDate = nil
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        beginCountdown(seconds: remaining)
    }

    func reset() {
        stopTicker()
        TimerAlert.cancelScheduled()
        silence()
        state = .idle
        remaining = 0
        endDate = nil
        totalDuration = 0
    }

    // Stops the alarm *and* the silent keep-alive.
    func silence() {
        isRinging = false
        TimerAlert.stopAudio()
    }

    func handleScenePhase(_ phase: ScenePhase) {
        guard state == .running else { return }
        if phase == .active, let endDate, endDate.timeIntervalSinceNow <= 0 {
            // It ran out while the app was not around to ring; the notification covered it.
            finish(playSound: false)
        } else {
            startTicker()
        }
    }
    #endif

    // MARK: - Internals

    #if os(iOS)
    private func refresh() {
        // A failed read says nothing about the timer, so it must not clear the snapshot.
        guard let alarms = try? AlarmManager.shared.alarms else { return }
        sync(with: alarms)
    }

    // The phase comes from the alarm, the time left from the snapshot. When the two
    // disagree — the system paused or resumed the alarm without going through
    // `TimerAlarm` — the snapshot is brought in line with the alarm.
    private func sync(with alarms: [Alarm]) {
        guard !isStarting else { return }

        var snapshot = TimerAlarm.snapshot
        if let stored = snapshot, !alarms.contains(where: { $0.id == stored.alarmID }) {
            // Its alarm is gone: stopped, cancelled, or rung out and dismissed.
            TimerAlarm.snapshot = nil
            snapshot = nil
        }

        guard let alarm = alarms.first(where: { $0.id == snapshot?.alarmID }) ?? alarms.first else {
            showIdle(ringing: false)
            return
        }
        alarmID = alarm.id

        if alarm.state == .alerting {
            showIdle(ringing: true)
            return
        }

        // A countdown without its anchor cannot be shown. Clearing it beats a timer that
        // rings with nothing on screen to stop or cancel it.
        guard var snapshot else {
            TimerAlarm.discard(alarm)
            showIdle(ringing: false)
            return
        }

        if alarm.state == .paused {
            if snapshot.pausedRemaining == nil {
                snapshot.pausedRemaining = snapshot.remaining()
                snapshot.endDate = nil
                TimerAlarm.snapshot = snapshot
            }
            show(snapshot, as: .paused)
        } else {
            if snapshot.endDate == nil {
                snapshot.endDate = Date.now.addingTimeInterval(snapshot.remaining())
                snapshot.pausedRemaining = nil
                TimerAlarm.snapshot = snapshot
            }
            show(snapshot, as: .running)
        }
    }

    private func show(_ snapshot: TimerSnapshot, as phase: State) {
        alarmID = snapshot.alarmID
        state = phase
        isRinging = false
        totalDuration = snapshot.totalDuration
        endDate = snapshot.endDate
        remaining = snapshot.remaining()
        if phase == .running, isInForeground {
            startTicker()
        } else {
            stopTicker()
        }
    }

    // Ringing keeps `alarmID`, which `silence()` needs to stop the alarm.
    private func showIdle(ringing: Bool) {
        stopTicker()
        state = .idle
        isRinging = ringing
        remaining = 0
        endDate = nil
        totalDuration = 0
        if !ringing { alarmID = nil }
    }
    #else
    private func beginCountdown(seconds: TimeInterval) {
        let end = Date().addingTimeInterval(seconds)
        endDate = end
        remaining = seconds
        state = .running
        TimerAlert.schedule(at: end)
        TimerAlert.startKeepAlive()
        startTicker()
    }

    private func finish(playSound: Bool) {
        stopTicker()
        remaining = 0
        endDate = nil
        totalDuration = 0
        state = .idle

        guard playSound else {
            silence()
            return
        }

        // We are handling it live, so the scheduled notification would only duplicate this.
        TimerAlert.cancelScheduled()
        isRinging = true
        TimerAlert.startRinging()
    }
    #endif

    private func startTicker() {
        stopTicker()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, !Task.isCancelled else { return }
                if self.tick() { return }
            }
        }
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
    }

    // Returns `true` once the countdown has reached zero, to end the ticker loop.
    private func tick() -> Bool {
        guard state == .running, let endDate else { return true }
        remaining = max(0, endDate.timeIntervalSinceNow)
        guard remaining <= 0 else { return false }
        #if !os(iOS)
        finish(playSound: true)
        #endif
        // On iOS AlarmKit rings, and its `.alerting` update moves the screen on.
        return true
    }
}
