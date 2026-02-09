import Foundation

/// Tracks which text field (weight or reps) has keyboard focus in a set row.
enum SetFocusField: Hashable {
    case weight(UUID)
    case reps(UUID)
}
