import Foundation
import SwiftData

final class SessionTemplateStore {

    static let shared = SessionTemplateStore()
    private init() {}
    
    func addTemplate(
        name: String,
        exercises: [String],
        in context: ModelContext
    ) {
        let template = SessionTemplate(name: name, exerciseNames: exercises)
        context.insert(template)
    }

    func removeTemplate(_ template: SessionTemplate, in context: ModelContext) {
        context.delete(template)
    }
}
