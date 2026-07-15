import Foundation
import SwiftData

@Model
final class ExerciseTemplate: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    @Relationship(deleteRule: .nullify, inverse: \Exercise.definition)
    var instances: [Exercise]?

    init(_ name: String) {
        self.name = name
    }

    /// Non-optional accessor for the CloudKit-optional relationship.
    var instanceList: [Exercise] { instances ?? [] }

    // MARK: - All-time statistics (aggregated over every instance)

    /// Instances that were actually performed (have at least one set).
    var performedInstances: [Exercise] { instanceList.filter { !$0.sets.isEmpty } }

    var timesPerformed: Int { performedInstances.count }

    var totalRepsAllTime: Int {
        instanceList.reduce(0) { $0 + $1.totalReps }
    }

    var totalVolumeAllTime: Double {
        instanceList.reduce(0) { $0 + $1.totalWeight }
    }

    /// Read-only summary of the most recent performed instance (an instance with sets).
    /// Pure display — never written back into `sets`, so a new exercise stays empty.
    var lastPerformedSummary: String {
        let done = instanceList
            .filter { !$0.sets.isEmpty }
            .sorted { ($0.session?.date ?? .distantPast) > ($1.session?.date ?? .distantPast) }

        guard let latest = done.first, let date = latest.session?.date else { return "" }

        // Locale-aware numeric date (e.g. "15.07.2026" in de, "7/15/2026" in en).
        let dateString = date.formatted(date: .numeric, time: .omitted)

        let lines = latest.sets.enumerated().map { index, set -> String in
            let label = set.name.isEmpty ? "Set \(index + 1)" : set.name
            let weight = set.weight.formatted(.number.precision(.fractionLength(0...2)))
            return "[ \(label) - \(weight)kg - \(set.reps) reps ]"
        }

        return String(localized: "Training on \(dateString)") + "\n" + lines.joined(separator: "\n")
    }
}
