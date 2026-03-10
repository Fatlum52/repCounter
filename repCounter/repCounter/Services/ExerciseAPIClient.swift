import Foundation

struct ExerciseSearchResult {
    let exercises: [ExerciseDTO]
    let total: Int
    let hasNextPage: Bool
    let hasPreviousPage: Bool
    let nextCursor: String?
    let previousCursor: String?
}

struct ExerciseAPIClient {

    private let baseURL = URL(string: "https://edb-with-videos-and-images-by-ascendapi.p.rapidapi.com")!
    private let rapidAPIHost = "edb-with-videos-and-images-by-ascendapi.p.rapidapi.com"

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

        let apiKey = Secrets.rapidAPIKey
        guard !apiKey.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }

        let endpoint = baseURL.appendingPathComponent("/api/v1/exercises")
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!

        var queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let after {
            queryItems.append(URLQueryItem(name: "after", value: after))
        }
        if let before {
            queryItems.append(URLQueryItem(name: "before", value: before))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(rapidAPIHost, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(ExerciseSearchResponseDTO.self, from: data)

        guard decoded.success else {
            throw URLError(.cannotParseResponse)
        }

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
        let apiKey = Secrets.rapidAPIKey
        guard !apiKey.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }

        let endpoint = baseURL.appendingPathComponent("/api/v1/exercises/\(id)")

        guard let url = URL(string: endpoint.absoluteString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(rapidAPIHost, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(ExerciseDetailResponseDTO.self, from: data)

        guard decoded.success else {
            throw URLError(.cannotParseResponse)
        }

        return decoded.data
    }
}
