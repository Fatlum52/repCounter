import Foundation
import SwiftData
import os

extension ModelContext {

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "repCounter",
        category: "Persistence"
    )

    // CloudKit only exports on save and SwiftData's autosave is opportunistic, so every
    // mutation saves explicitly. The `hasChanges` guard makes redundant calls free.
    func saveIfNeeded() {
        guard hasChanges else { return }
        do {
            try save()
        } catch {
            Self.logger.error("Save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
