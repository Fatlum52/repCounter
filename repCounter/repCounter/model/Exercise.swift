import Foundation
import SwiftData

@Model
final class Exercise: Identifiable {
    var id: UUID = UUID()
    var name: String
    var quickReps: Int = 0 // Reps, die über +/- gezählt werden
    var sets: [ExerciseSet] = [] // „richtige“ Sets (als eingebettete Werttypen gespeichert)
    var notes: String = ""
    
    init(_ name: String) {
        self.name = name
    }

    struct ExerciseSet: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var name: String
        var reps: Int = 0
        
        init(_ name: String) {
            self.name = name
        }
    }

    var totalReps: Int {
        quickReps + sets.reduce(0) { $0 + $1.reps }
    }
}
