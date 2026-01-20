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
