import Foundation

#if os(iOS)
import AppIntents

// Back the Live Activity's buttons. As `LiveActivityIntent`s compiled into both targets
// they run in the app process, so they share `TimerAlarm`'s snapshot with the app.

struct PauseTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Pause"
    static let isDiscoverable = false

    @Parameter(title: "Timer")
    var alarmID: String

    init() {}
    init(alarmID: UUID) { self.alarmID = alarmID.uuidString }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: alarmID) { try TimerAlarm.pause(id: id) }
        return .result()
    }
}

struct ResumeTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Resume"
    static let isDiscoverable = false

    @Parameter(title: "Timer")
    var alarmID: String

    init() {}
    init(alarmID: UUID) { self.alarmID = alarmID.uuidString }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: alarmID) { try TimerAlarm.resume(id: id) }
        return .result()
    }
}

struct CancelTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Cancel"
    static let isDiscoverable = false

    @Parameter(title: "Timer")
    var alarmID: String

    init() {}
    init(alarmID: UUID) { self.alarmID = alarmID.uuidString }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: alarmID) { try TimerAlarm.cancel(id: id) }
        return .result()
    }
}

struct StopTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop"
    static let isDiscoverable = false

    @Parameter(title: "Timer")
    var alarmID: String

    init() {}
    init(alarmID: UUID) { self.alarmID = alarmID.uuidString }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: alarmID) { try TimerAlarm.stop(id: id) }
        return .result()
    }
}
#endif
