import Foundation

struct MetadataDTO: Decodable {
    let totalExercises: Int
    let totalPages: Int
    let currentPage: Int
    let previousPage: String?
    let nextPage: String?
}
