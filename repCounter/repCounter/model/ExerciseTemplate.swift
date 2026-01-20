import Foundation
import SwiftData

@Model
final class ExerciseTemplate: Identifiable {
    var id: UUID = UUID()
    var name: String
    
    init(_ name: String) {
        self.name = name
    }
}
