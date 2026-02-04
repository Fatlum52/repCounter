import Foundation

struct ExerciseDTO: Decodable {
    let exerciseId: String
    let name: String
    let gifUrl: String
    let targetMuscles: [String]
    let bodyParts: [String]
    let equipments: [String]
    let secondaryMuscles: [String]
    let instructions: [String]
}
