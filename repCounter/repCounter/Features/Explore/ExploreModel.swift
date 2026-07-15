import Foundation

/// Search + cursor-pagination state for `ExploreView`.
/// `@MainActor` means every mutation runs on the main actor, so the view no longer
/// needs `await MainActor.run { … }` blocks.
@MainActor
@Observable
final class ExploreModel {

    var searchText = ""
    var results: [ExerciseDTO] = []
    var isLoading = false
    var errorMessage: String?
    var hasSearched = false

    var currentPage = 1
    var totalResults = 0
    var hasNextPage = false
    private var pageCursors: [String?] = [nil]

    let pageSize: Int
    private let apiClient = ExerciseAPIClient()

    init(pageSize: Int) {
        self.pageSize = pageSize
    }

    var totalPages: Int {
        guard totalResults > 0 else { return 1 }
        return max(1, Int(ceil(Double(totalResults) / Double(pageSize))))
    }

    // MARK: - Actions

    func performSearch(reset: Bool = true) async {
        guard !trimmedQuery.isEmpty else { return }
        if reset { resetPagination() }
        hasSearched = true
        await loadPage(1, afterCursor: nil)
    }

    func goToNextPage() async {
        guard hasNextPage else { return }
        let target = currentPage + 1
        guard target - 1 < pageCursors.count else { return }
        await loadPage(target, afterCursor: pageCursors[target - 1])
    }

    func goToPreviousPage() async {
        guard currentPage > 1 else { return }
        let target = currentPage - 1
        await loadPage(target, afterCursor: pageCursors[target - 1])
    }

    func retryCurrentPage() async {
        let cursor = (currentPage - 1 < pageCursors.count) ? pageCursors[currentPage - 1] : nil
        await loadPage(currentPage, afterCursor: cursor)
    }

    func clearSearch() {
        searchText = ""
        resetState()
    }

    func resetState() {
        results = []
        hasSearched = false
        errorMessage = nil
        resetPagination()
    }

    // MARK: - Internals

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func resetPagination() {
        currentPage = 1
        totalResults = 0
        hasNextPage = false
        pageCursors = [nil]
    }

    private func loadPage(_ page: Int, afterCursor: String?) async {
        let query = trimmedQuery
        guard !query.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        do {
            let result = try await apiClient.searchExercises(name: query, limit: pageSize, after: afterCursor)
            results = result.exercises
            totalResults = result.total
            hasNextPage = result.hasNextPage
            currentPage = page

            if result.hasNextPage, let next = result.nextCursor {
                if pageCursors.count == page {
                    pageCursors.append(next)
                } else if page < pageCursors.count {
                    pageCursors[page] = next
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
