import Foundation
import SwiftData

@Model
final class Session: Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var name: String = ""
    @Relationship(deleteRule: .cascade, inverse: \Exercise.session)
    var exercises: [Exercise]?

    init(name: String, date: Date = .now) {
        self.name = name
        self.date = date
    }

    /// Non-optional accessor for the CloudKit-optional relationship.
    var exerciseList: [Exercise] { exercises ?? [] }

    var isToday: Bool { Calendar.current.isDateInToday(date) }

    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM y"
        return dateFormatter.string(from: date)
    }
}
