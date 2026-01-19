import Foundation

final class ExerciseTemplate: Identifiable {
    let id: UUID = UUID()
    let name: String
    
    init(_ name: String) {
        self.name = name
    }
}
