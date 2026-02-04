import Foundation

struct ExerciseAPIClient {
    
    private let baseURL = URL(string: "https://oss.exercisedb.dev")!
    
    func fetchExercises() async throws -> [ExerciseDTO] {
        // crate url
        let url = baseURL.appendingPathComponent("/api/v1/exercises")
        
        // fetch data
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(ExerciseSearchResponseDTO.self, from: data)
        
        guard decoded.success else {
            throw URLError(.cannotParseResponse)
        }
        
        return decoded.data
    }
}
