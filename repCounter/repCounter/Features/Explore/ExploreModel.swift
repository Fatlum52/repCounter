import Foundation

// Search + pagination state for `ExploreView`. The API's name filter is fuzzy and returns
// matches in arbitrary order ("Bench Press" came back 11th of 12 for "bench press"), so the
// model loads every match once, ranks it by name relevance, and pages through it locally.
@MainActor
@Observable
final class ExploreModel {

    var searchText = ""
    var isLoading = false
    var errorMessage: String?
    var hasSearched = false
    var currentPage = 1

    private var allResults: [ExerciseDTO] = []
    // The query the current results belong to — retry uses it even if the field was edited since.
    private var activeQuery = ""
    private var searchTask: Task<Void, Never>?

    let pageSize: Int
    private let apiClient = ExerciseAPIClient()

    init(pageSize: Int) {
        self.pageSize = pageSize
    }

    var results: [ExerciseDTO] {
        let start = (currentPage - 1) * pageSize
        guard start < allResults.count else { return [] }
        return Array(allResults[start..<min(start + pageSize, allResults.count)])
    }

    var totalResults: Int { allResults.count }

    var totalPages: Int {
        max(1, Int(ceil(Double(totalResults) / Double(pageSize))))
    }

    var hasNextPage: Bool { currentPage < totalPages }

    // MARK: - Actions

    func search() {
        let query = trimmedQuery
        guard !query.isEmpty else { return }
        startSearch(for: query)
    }

    func goToNextPage() {
        guard hasNextPage else { return }
        currentPage += 1
    }

    func goToPreviousPage() {
        guard currentPage > 1 else { return }
        currentPage -= 1
    }

    func retry() {
        guard !activeQuery.isEmpty else { return }
        startSearch(for: activeQuery)
    }

    func clearSearch() {
        searchText = ""
        resetState()
    }

    func resetState() {
        searchTask?.cancel()
        searchTask = nil
        allResults = []
        activeQuery = ""
        currentPage = 1
        isLoading = false
        hasSearched = false
        errorMessage = nil
    }

    // MARK: - Internals

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func startSearch(for query: String) {
        // A newer search supersedes one still in flight, so a slow response can't overwrite it.
        searchTask?.cancel()
        activeQuery = query
        hasSearched = true
        isLoading = true
        errorMessage = nil
        searchTask = Task {
            do {
                let matches = try await apiClient.searchAllExercises(name: query)
                try Task.checkCancellation()
                allResults = Self.rankedByRelevance(matches, query: query)
                currentPage = 1
            } catch {
                if Task.isCancelled { return }
                allResults = []
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - Relevance

    /// Exact name first, then names starting with the query, then names containing the whole
    /// phrase, then by how many query words match. Shorter names win ties; otherwise API order.
    static func rankedByRelevance(_ exercises: [ExerciseDTO], query: String) -> [ExerciseDTO] {
        let phrase = normalized(query)
        let queryWords = phrase.split(separator: " ")
        return exercises.enumerated()
            .map { index, exercise in
                let name = normalized(exercise.name)
                let nameWords = name.split(separator: " ")
                let missing = queryWords.filter { word in !nameWords.contains { $0.hasPrefix(word) } }.count
                let tier: Int
                if name == phrase {
                    tier = 0
                } else if name.hasPrefix(phrase) {
                    tier = 1
                } else if " \(name)".contains(" \(phrase)") {
                    tier = 2
                } else {
                    tier = 3 + missing
                }
                return (exercise, (tier, nameWords.count, index))
            }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    // Case/diacritic-insensitive, punctuation as word breaks: "Pull-up " → "pull up".
    private static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
