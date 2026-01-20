import Foundation
import SwiftData

@Model
final class SessionTemplate: Identifiable {
    var id: UUID = UUID()
    var name: String
    var exerciseNames: [String]
    
    init(name: String, exerciseNames: [String]) {
        self.name = name
        self.exerciseNames = exerciseNames
    }
}
