import Foundation
import SwiftData

final class SessionTemplateStore {

    static let shared = SessionTemplateStore()
    private init() {}

    @discardableResult
    func addTemplate(
        name: String,
        exerciseDefinitionIDs: [UUID] = [],
        in context: ModelContext
    ) -> SessionTemplate {
        let template = SessionTemplate(name: name, exerciseDefinitionIDs: exerciseDefinitionIDs)
        context.insert(template)
        context.saveIfNeeded()
        return template
    }

    func removeTemplate(_ template: SessionTemplate, in context: ModelContext) {
        context.delete(template)
        context.saveIfNeeded()
    }
}
