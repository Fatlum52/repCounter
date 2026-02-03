import Foundation
import SwiftData

@Model
final class Session: Identifiable {
    var id           = UUID()
    var date         = Date()
    var name: String = "Training vom "
    @Relationship(deleteRule: .cascade)
    var exercises: [Exercise] = []
    
    init(name: String) {
        self.name = name
        self.date = Date()
        self.exercises = []
    }
    
    init(_ name: String, _ exercises: [Exercise]) {
        self.name = name
        self.date = Date()
        self.exercises = exercises
    }
    
    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM y"
        return dateFormatter.string(from: date)
    }
    
    func getFormattedDate() -> String {
        return formattedDate
    }
}
