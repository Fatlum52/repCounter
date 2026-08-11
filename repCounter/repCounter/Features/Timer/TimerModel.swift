import Foundation
import SwiftUI

/// Countdown state for `TimerView`.
///
/// The countdown is anchored to an absolute `endDate`, not to a counter that ticks
/// down. The ticker only *reads* the clock, so a stall — a suspended app, a dropped
/// tick, a slow frame — can never make the timer drift: whenever it next runs, the
/// remaining time is still correct.
@MainActor
@Observable
final class TimerModel {

    enum State {
        case idle, running, paused, finished
    }

    /// macOS starts empty because its fields are typed into — a prefilled value would
    /// just have to be deleted first. The iOS wheel opens on a usable default instead,
    /// since spinning away from it costs nothing.
    #if os(macOS)
    private static let defaultMinutes = 0
    #else
    private static let defaultMinutes = 2
    #endif

    /// Duration selection, kept separate from the running countdown so cancelling
    /// returns the user to the duration they last dialled in.
    var selectedMinutes = TimerModel.defaultMinutes
    var selectedSeconds = 0

    private(set) var state: State = .idle
    private(set) var remaining: TimeInterval = 0

    private var endDate: Date?
    private var totalDuration: TimeInterval = 0
    private var ticker: Task<Void, Never>?

    // MARK: - Derived

    var selectedDuration: TimeInterval {
        TimeInterval(selectedMinutes * 60 + selectedSeconds)
    }

    var canStart: Bool { selectedDuration > 0 }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return min(max(1 - remaining / totalDuration, 0), 1)
    }

    /// `mm:ss`, rounded up so a fresh 2:00 timer reads "02:00" rather than "01:59".
    var formattedRemaining: String {
        let seconds = Int(max(0, remaining.rounded(.up)))
        return Duration.seconds(seconds)
            .formatted(.time(pattern: .minuteSecond(padMinuteToLength: 2)))
    }

    // MARK: - Actions

    func start() {
        guard canStart else { return }
        totalDuration = selectedDuration
        beginCountdown(seconds: totalDuration)
    }

    func pause() {
        guard state == .running, let endDate else { return }
        stopTicker()
        TimerAlert.cancelScheduled()
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
        state = .idle
        remaining = 0
        endDate = nil
        totalDuration = 0
    }

    /// A suspended app runs no ticker, so the countdown is re-checked against the
    /// clock on every return to the foreground.
    func handleScenePhase(_ phase: ScenePhase) {
        guard state == .running else { return }
        switch phase {
        case .active:
            if let endDate, endDate.timeIntervalSinceNow <= 0 {
                // It ran out while we were away — the notification already sounded,
                // so catch up on the state without making noise a second time.
                finish(playSound: false)
            } else {
                startTicker()
            }
        default:
            stopTicker()
        }
    }

    // MARK: - Internals

    private func beginCountdown(seconds: TimeInterval) {
        let end = Date().addingTimeInterval(seconds)
        endDate = end
        remaining = seconds
        state = .running
        TimerAlert.schedule(at: end)
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

    /// Returns `true` once the countdown has reached zero, to end the ticker loop.
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
        state = .finished
        if playSound {
            // We are on screen, so the scheduled notification would only duplicate this.
            TimerAlert.cancelScheduled()
            TimerAlert.playNow()
        }
    }
}
