import Foundation

struct ExerciseDTO: Decodable, Identifiable, Hashable {
    let exerciseId: String
    let name: String
    let imageUrl: String?
    let videoUrl: String?
    let targetMuscles: [String]
    let bodyParts: [String]
    let equipments: [String]
    let secondaryMuscles: [String]
    let instructions: [String]?

    var id: String { exerciseId }
}
