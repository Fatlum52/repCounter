import Foundation

final class SessionTemplate: Identifiable {
    let id: UUID = UUID()
    let name: String
    let exerciseNames: [String]
    
    init(name: String, exerciseNames: [String]) {
        self.name = name
        self.exerciseNames = exerciseNames
    }
}
