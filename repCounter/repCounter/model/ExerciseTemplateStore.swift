import Foundation
import SwiftData

final class ExerciseTemplateStore {

    static let shared = ExerciseTemplateStore()
    private init() {}

    func addTemplate(name: String, in context: ModelContext) {
        let template = ExerciseTemplate(name)
        context.insert(template)
    }

    func removeTemplate(_ template: ExerciseTemplate, in context: ModelContext) {
        context.delete(template)
    }

    /// Find-or-create by name (case-insensitive). Single source of truth for
    /// exercise definitions: picking an existing library entry never creates a duplicate.
    @discardableResult
    func definition(named name: String, in context: ModelContext) -> ExerciseTemplate {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = (try? context.fetch(FetchDescriptor<ExerciseTemplate>())) ?? []
        if let existing = all.first(where: { $0.name.compare(trimmed, options: .caseInsensitive) == .orderedSame }) {
            return existing
        }
        let created = ExerciseTemplate(trimmed)
        context.insert(created)
        return created
    }

    /// Late ID→Definition mapping: fetches all templates and orders them in-memory
    /// by the given ids. Missing (deleted) ids are dropped. Only ids are stored;
    /// the name is resolved here at render/build time.
    func definitions(forIDs ids: [UUID], in context: ModelContext) -> [ExerciseTemplate] {
        let all = (try? context.fetch(FetchDescriptor<ExerciseTemplate>())) ?? []
        let byID = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return ids.compactMap { byID[$0] }
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
