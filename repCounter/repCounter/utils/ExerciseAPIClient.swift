import Foundation

struct ExerciseAPIClient {
    
    private let baseURL = URL(string: "https://oss.exercisedb.dev")!
    
    func searchExercises(search: String, limit: Int = 10) async throws -> [ExerciseDTO] {
        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        // create url
        let endpoint = baseURL.appendingPathComponent("/api/v1/exercises")
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        
        components.queryItems = [
            URLQueryItem(name: "search", value: trimmed),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        // fetch data
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        // decode data
        let decoded = try JSONDecoder().decode(ExerciseSearchResponseDTO.self, from: data)
        
        guard decoded.success else {
            throw URLError(.cannotParseResponse)
        }
        
        return decoded.data
    }
}
