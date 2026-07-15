import Foundation
import SwiftData

@Model
final class SessionTemplate: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    /// Ordered references to `ExerciseTemplate.id`; array order = display order.
    /// No names stored → no drift on rename. ID→name mapping happens late (at render/build).
    var exerciseDefinitionIDs: [UUID] = []

    init(name: String, exerciseDefinitionIDs: [UUID] = []) {
        self.name = name
        self.exerciseDefinitionIDs = exerciseDefinitionIDs
    }
}
