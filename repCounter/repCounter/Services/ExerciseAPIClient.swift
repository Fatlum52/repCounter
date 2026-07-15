import Foundation

struct ExerciseSearchResult {
    let exercises: [ExerciseDTO]
    let total: Int
    let hasNextPage: Bool
    let hasPreviousPage: Bool
    let nextCursor: String?
    let previousCursor: String?
}

enum APIError: LocalizedError {
    case missingKey
    case badStatus(Int)
    case notSuccess

    var errorDescription: String? {
        switch self {
        case .missingKey:
            return String(localized: "API key is missing. Add it to Secrets.plist.")
        case .badStatus(let code):
            return String(localized: "The server returned an error (status \(code)).")
        case .notSuccess:
            return String(localized: "The server response could not be processed.")
        }
    }
}

struct ExerciseAPIClient {

    private let baseURL = URL(string: "https://edb-with-videos-and-images-by-ascendapi.p.rapidapi.com")!
    private let rapidAPIHost = "edb-with-videos-and-images-by-ascendapi.p.rapidapi.com"
    private let decoder = JSONDecoder()

    // MARK: - Shared request

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let key = Secrets.rapidAPIKey
        guard !key.isEmpty else { throw APIError.missingKey }

        var request = URLRequest(url: url)
        request.setValue(rapidAPIHost, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(key, forHTTPHeaderField: "x-rapidapi-key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw APIError.badStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Endpoints

    func searchExercises(
        name: String,
        limit: Int = 10,
        after: String? = nil,
        before: String? = nil
    ) async throws -> ExerciseSearchResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ExerciseSearchResult(
                exercises: [], total: 0,
                hasNextPage: false, hasPreviousPage: false,
                nextCursor: nil, previousCursor: nil
            )
        }

        let endpoint = baseURL.appendingPathComponent("/api/v1/exercises")
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let after { queryItems.append(URLQueryItem(name: "after", value: after)) }
        if let before { queryItems.append(URLQueryItem(name: "before", value: before)) }
        components.queryItems = queryItems

        guard let url = components.url else { throw URLError(.badURL) }

        let decoded: ExerciseSearchResponseDTO = try await get(url)
        guard decoded.success else { throw APIError.notSuccess }

        let meta = decoded.meta
        return ExerciseSearchResult(
            exercises: decoded.data,
            total: meta.total ?? decoded.data.count,
            hasNextPage: meta.hasNextPage ?? false,
            hasPreviousPage: meta.hasPreviousPage ?? false,
            nextCursor: meta.nextCursor,
            previousCursor: meta.previousCursor
        )
    }

    func fetchExercise(id: String) async throws -> ExerciseDTO {
        let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        guard let url = URL(string: "\(baseURL.absoluteString)/api/v1/exercises/\(encoded)") else {
            throw URLError(.badURL)
        }

        let decoded: ExerciseDetailResponseDTO = try await get(url)
        guard decoded.success else { throw APIError.notSuccess }
        return decoded.data
    }
}
