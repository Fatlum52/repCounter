import Foundation
import SwiftData

final class TrainingSession: Identifiable {
    let id           = UUID()
    var date         = Date()
    var name: String = "Training vom "
    var exercises: [Exercise] = []
    
    init(_ name: String, _ exercises: [Exercise]) {
        self.name = name
        self.exercises = exercises
        self.date = Date()
    }
    
    func getFormattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM y"
        return dateFormatter.string(from: date)
    }
}
