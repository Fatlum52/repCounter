import Foundation

struct ExerciseSearchResponseDTO: Decodable {
    let success: Bool
    let meta: MetadataDTO
    let data: [ExerciseDTO]
}
