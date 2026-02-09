import Foundation

struct ExerciseAPIClient {

    private let baseURL = URL(string: "https://edb-with-videos-and-images-by-ascendapi.p.rapidapi.com")!
    private let rapidAPIHost = "edb-with-videos-and-images-by-ascendapi.p.rapidapi.com"

    func searchExercises(search: String, limit: Int = 10) async throws -> [ExerciseDTO] {
        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let apiKey = Secrets.rapidAPIKey
        guard !apiKey.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }

        // Build URL
        let endpoint = baseURL.appendingPathComponent("/api/v1/exercises")
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!

        components.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        // Build request with RapidAPI headers
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(rapidAPIHost, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")

        // Fetch
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        // Decode
        let decoded = try JSONDecoder().decode(ExerciseSearchResponseDTO.self, from: data)

        guard decoded.success else {
            throw URLError(.cannotParseResponse)
        }

        return decoded.data
    }
}
