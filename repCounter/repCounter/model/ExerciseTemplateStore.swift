import Foundation
import SwiftData

final class ExerciseTemplateStore {

    static let shared = ExerciseTemplateStore()
    private init() {}

    func addTemplate(name: String, in context: ModelContext) {
        let template = ExerciseTemplate(name)
        context.insert(template)
        context.saveIfNeeded()
    }

    func removeTemplate(_ template: ExerciseTemplate, in context: ModelContext) {
        context.delete(template)
        context.saveIfNeeded()
    }

    // Find-or-create by name (case-insensitive). Single source of truth for
    // exercise definitions: picking an existing library entry never creates a duplicate.
    @discardableResult
    func definition(named name: String, in context: ModelContext) -> ExerciseTemplate {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = (try? context.fetch(FetchDescriptor<ExerciseTemplate>())) ?? []
        if let existing = all.first(where: { $0.name.compare(trimmed, options: .caseInsensitive) == .orderedSame }) {
            return existing
        }
        let created = ExerciseTemplate(trimmed)
        context.insert(created)
        context.saveIfNeeded()
        return created
    }

    // Late ID→definition mapping, ordered by `ids`. Deleted ids are dropped.
    func definitions(forIDs ids: [UUID], in context: ModelContext) -> [ExerciseTemplate] {
        let all = (try? context.fetch(FetchDescriptor<ExerciseTemplate>())) ?? []
        let byID = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return ids.compactMap { byID[$0] }
    }

    // Merges same-name templates, keeping the lowest `id` so every device picks the same
    // survivor. Needed because CloudKit dedups by its record id, not by our `id` attribute.
    @discardableResult
    func deduplicate(in context: ModelContext) -> Int {
        let all = (try? context.fetch(FetchDescriptor<ExerciseTemplate>())) ?? []
        let groups = Dictionary(grouping: all) {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        var replacements: [UUID: UUID] = [:] // loser id → winner id
        var losers: [ExerciseTemplate] = []

        for (_, group) in groups where group.count > 1 {
            let ordered = group.sorted { $0.id.uuidString < $1.id.uuidString }
            let winner = ordered[0]
            for loser in ordered.dropFirst() {
                // Re-pointing the exercise updates `instances` too (it is the inverse).
                for exercise in loser.instanceList {
                    exercise.definition = winner
                }
                replacements[loser.id] = winner.id
                losers.append(loser)
            }
        }

        guard !losers.isEmpty else { return 0 }

        // Session templates reference definitions by raw id, not by relationship,
        // so they have to be remapped by hand.
        let sessionTemplates = (try? context.fetch(FetchDescriptor<SessionTemplate>())) ?? []
        for template in sessionTemplates {
            var seen = Set<UUID>()
            let remapped = template.exerciseDefinitionIDs
                .map { replacements[$0] ?? $0 }
                .filter { seen.insert($0).inserted } // a merge can collapse two entries into one
            if remapped != template.exerciseDefinitionIDs {
                template.exerciseDefinitionIDs = remapped
            }
        }

        losers.forEach { context.delete($0) }
        try? context.save()
        return losers.count
    }

    // MARK: - Defaults (hardcoded, not in SwiftData)

    static let defaultTemplateNames: [String] = [
        "Pushup",
        "Pullup",
        "Chinup",
        "Dip",
        "Muscle Up",
        "Bench Press",
        "Squat",
        "Deadlift",
        "Shoulder Press",
        "Pike Pushup",
        "Bicep Curl"
    ]
}
