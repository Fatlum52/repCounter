import Foundation

struct ExerciseSearchResponseDTO: Decodable {
    let success: Bool
    let metadata: MetadataDTO
    let data: [ExerciseDTO]
}
