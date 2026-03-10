import Foundation

struct ExerciseDetailResponseDTO: Decodable {
    let success: Bool
    let data: ExerciseDTO
}
