import Foundation
import SwiftData

@Model
final class Exercise: Identifiable {
    var id: UUID = UUID()
    var name: String
    var order: Int = 0  // Order within the training session
    var sets: [ExerciseSet] = []
    var notes: String = ""
    var mediaItems: [MediaItem] = [] // images or videos within exercise
    
    init(_ name: String) {
        self.name = name
    }

    struct ExerciseSet: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var name: String
        var reps: Int = 0
        var weight: Int = 0
        
        init(_ name: String) {
            self.name = name
        }
    }
    
    struct MediaItem: Identifiable, Codable {
        var id: UUID = UUID()
        var fileName: String
        var fileType: MediaType
        var createdAt: Date = Date()
        
        enum MediaType: String, Codable {
            case image, video
        }
    }

    var totalReps: Int {
        sets.reduce(0) { $0 + $1.reps }
    }

    var totalWeight: Int {
        sets.reduce(0) { $0 + ($1.weight * max($1.reps, 1)) }
    }
}

