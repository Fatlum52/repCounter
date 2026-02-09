import Foundation

struct MetadataDTO: Decodable {
    let total: Int?
    let hasNextPage: Bool?
    let hasPreviousPage: Bool?
    let nextCursor: String?
}
