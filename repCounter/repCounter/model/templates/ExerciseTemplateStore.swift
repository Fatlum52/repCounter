import Foundation

final class ExerciseTemplateStore {

    static let shared = ExerciseTemplateStore()

    private(set) var templates: [ExerciseTemplate]

    private init() {
        self.templates = Self.defaultTemplates
    }

    func addTemplate(name: String) {
        templates.append(ExerciseTemplate(name))
    }

    func removeTemplate(id: UUID) {
        templates.removeAll { $0.id == id }
    }

    // MARK: - Defaults

    private static let defaultTemplates: [ExerciseTemplate] = [
        .init("Pushup"),
        .init("Pullup"),
        .init("Chinup"),
        .init("Dip"),
        .init("Muscle Up"),
        .init("Bench Press"),
        .init("Squat"),
        .init("Deadlift"),
        .init("Shoulder Press"),
        .init("Pike Pushup"),
        .init("Bicep Curl")
    ]
}
