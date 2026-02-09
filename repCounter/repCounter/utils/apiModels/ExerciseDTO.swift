import Foundation

struct ExerciseDTO: Decodable, Identifiable {
    let exerciseId: String
    let name: String
    let imageUrl: String?
    let targetMuscles: [String]
    let bodyParts: [String]
    let equipments: [String]
    let secondaryMuscles: [String]

    // Identifiable conformance
    var id: String { exerciseId }
}
