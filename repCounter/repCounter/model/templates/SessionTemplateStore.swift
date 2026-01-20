import Foundation

final class SessionTemplateStore {

    static let shared = SessionTemplateStore()

    private(set) var templates: [SessionTemplate] = []

    private init() {}

    func addTemplate(
        name: String,
        exerciseNames: [String]
    ) {
        let template = SessionTemplate(
            name: name,
            exerciseNames: exerciseNames
        )
        templates.append(template)
    }

    func removeTemplate(id: UUID) {
        templates.removeAll { $0.id == id }
    }
}
