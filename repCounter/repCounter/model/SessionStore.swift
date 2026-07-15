import Foundation
import SwiftData

/// Central place for creating/removing sessions and their exercises.
/// Views only pick; they never call `modelContext.insert/.delete` directly.
final class SessionStore {

    static let shared = SessionStore()
    private init() {}

    @discardableResult
    func createSession(name: String, date: Date = .now, in context: ModelContext) -> Session {
        let session = Session(name: name, date: date)
        context.insert(session)
        return session
    }

    /// Builds a session from a template. Exercise definitions are resolved from
    /// `exerciseDefinitionIDs` via `definitions(forIDs:)` (in template order) and
    /// assigned ascending `order` (0…n), so session order == template order.
    @discardableResult
    func createSession(from template: SessionTemplate, in context: ModelContext) -> Session {
        let session = createSession(name: template.name, in: context)
        let definitions = ExerciseTemplateStore.shared.definitions(forIDs: template.exerciseDefinitionIDs, in: context)
        for (index, definition) in definitions.enumerated() {
            let exercise = Exercise(definition.name)
            exercise.definition = definition
            exercise.session = session
            exercise.order = index
            context.insert(exercise)
        }
        return session
    }

    /// Adds an exercise to a session from a library definition. Snapshots the
    /// definition name into the exercise and appends at the end (ascending order).
    func addExercise(_ definition: ExerciseTemplate, to session: Session, in context: ModelContext) {
        let exercise = Exercise(definition.name)
        exercise.definition = definition
        exercise.session = session
        exercise.order = (session.exerciseList.map(\.order).max() ?? -1) + 1
        context.insert(exercise)
    }

    func remove(_ session: Session, in context: ModelContext) {
        FileManagerHelper.deleteMediaFiles(for: session)
        context.delete(session)
    }

    func remove(_ exercise: Exercise, in context: ModelContext) {
        FileManagerHelper.deleteMediaFiles(for: exercise)
        context.delete(exercise)
    }
}
