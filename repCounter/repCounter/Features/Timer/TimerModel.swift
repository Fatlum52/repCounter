import Foundation
import SwiftUI

// Countdown state for `TimerView`. Anchored to an absolute `endDate` rather than a
// ticking counter, so a suspended app or a dropped tick can never make it drift.
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

    // The lock screen's Stop button runs `StopTimerIntent` in this process and posts here.
    // The loop holds `self` weakly and returns on the first post after deallocation, so it
    // needs no cancellation from `deinit` (which could not touch actor state anyway).
    init() {
        Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .repCounterStopTimer) {
                guard let self else { return }
                self.silence()
            }
        }
    }

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
        #if os(iOS)
        TimerLiveActivity.update(
            endDate: Date().addingTimeInterval(remaining),
            pausedRemaining: remaining
        )
        #endif
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

    // Stops the alarm *and* the silent keep-alive, and clears the lock screen.
    func silence() {
        isRinging = false
        TimerAlert.stopAudio()
        #if os(iOS)
        TimerLiveActivity.end()
        #endif
    }

    // The audio session keeps the process alive in the background, so the ticker is left
    // running there — that is what lets the alarm fire on a locked device.
    func handleScenePhase(_ phase: ScenePhase) {
        guard state == .running else { return }
        if phase == .active, let endDate, endDate.timeIntervalSinceNow <= 0 {
            // It ran out while iOS had us suspended after all; the notification covered it.
            finish(playSound: false)
        } else {
            startTicker()
        }
    }

    // MARK: - Internals

    private func beginCountdown(seconds: TimeInterval) {
        let end = Date().addingTimeInterval(seconds)
        endDate = end
        remaining = seconds
        state = .running
        TimerAlert.schedule(at: end)
        TimerAlert.startKeepAlive()
        #if os(iOS)
        TimerLiveActivity.start(endDate: end)
        #endif
        startTicker()
    }

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
        finish(playSound: true)
        return true
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
        #if os(iOS)
        TimerLiveActivity.update(endDate: Date(), isRinging: true)
        #endif
    }
}
