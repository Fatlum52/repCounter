import SwiftUI

struct ExploreView: View {

    @State private var searchText = ""
    @State private var results: [ExerciseDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasSearched = false
    @State private var selectedExercise: ExerciseDTO?

    // Cursor-based pagination
    @State private var currentPage = 1
    @State private var totalResults = 0
    @State private var hasNextPage = false
    @State private var pageCursors: [String?] = [nil]

    private let apiClient = ExerciseAPIClient()

#if os(iOS)
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    private let pageSize = 10
#elseif os(macOS)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)
    private let pageSize = 12
#endif

    var body: some View {
        ZStack {
            Background()

            VStack(spacing: 16) {
                searchBar

                if isLoading {
                    Spacer()
                    ProgressView("Searching...")
                        .progressViewStyle(.circular)
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    errorView(error)
                    Spacer()
                } else if results.isEmpty && hasSearched {
                    Spacer()
                    emptyStateView
                    Spacer()
                } else if !results.isEmpty {
                    resultsGrid
                    paginationBar
                } else {
                    Spacer()
                    initialStateView
                    Spacer()
                }
            }
            .padding(.top, 16)
        }
        .navigationTitle("Explore")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
#endif
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search for exercises...", text: $searchText)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .onSubmit { performSearch(reset: true) }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        resetState()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(12)

            Button {
                performSearch(reset: true)
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.borderedProminent)
            .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Results Grid
    private var resultsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(results) { exercise in
                    Button {
                        selectedExercise = exercise
                    } label: {
                        ExerciseCardView(exercise: exercise)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $selectedExercise) { exercise in
            NavigationStack {
                ExerciseExploreDetailView(exercise: exercise)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { selectedExercise = nil }
                        }
                    }
            }
#if os(macOS)
            .frame(minWidth: 550, idealWidth: 650, maxWidth: 750, minHeight: 450, idealHeight: 550, maxHeight: 700)
#endif
        }
    }

    // MARK: - Pagination

    private var totalPages: Int {
        guard totalResults > 0 else { return 1 }
        return max(1, Int(ceil(Double(totalResults) / Double(pageSize))))
    }

    private var paginationBar: some View {
        HStack {
            Button {
                goToPreviousPage()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
            }
            .disabled(currentPage <= 1)

            Spacer()

            if totalResults > 0 {
                Text("Page \(currentPage) of \(totalPages)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                goToNextPage()
            } label: {
                HStack(spacing: 6) {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
            }
            .disabled(!hasNextPage)
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No exercises found")
                .font(.headline)
            Text("Try a different search term")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Initial State
    private var initialStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Discover Exercises")
                .font(.headline)
            Text("Search for exercises to explore")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Something went wrong")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                let cursor = (currentPage - 1 < pageCursors.count) ? pageCursors[currentPage - 1] : nil
                loadPage(currentPage, afterCursor: cursor)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Pagination Actions

    private func goToNextPage() {
        guard hasNextPage else { return }
        let targetPage = currentPage + 1
        guard targetPage - 1 < pageCursors.count else { return }
        let cursor = pageCursors[targetPage - 1]
        loadPage(targetPage, afterCursor: cursor)
    }

    private func goToPreviousPage() {
        guard currentPage > 1 else { return }
        let targetPage = currentPage - 1
        let cursor = pageCursors[targetPage - 1]
        loadPage(targetPage, afterCursor: cursor)
    }

    // MARK: - Search

    private func loadPage(_ page: Int, afterCursor: String?) {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await apiClient.searchExercises(
                    name: trimmed,
                    limit: pageSize,
                    after: afterCursor
                )
                await MainActor.run {
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

                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func performSearch(reset: Bool) {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if reset {
            resetState()
        }

        hasSearched = true
        loadPage(1, afterCursor: nil)
    }

    private func resetState() {
        results = []
        hasSearched = false
        errorMessage = nil
        currentPage = 1
        totalResults = 0
        hasNextPage = false
        pageCursors = [nil]
    }
}

// MARK: - Exercise Card View
struct ExerciseCardView: View {
    let exercise: ExerciseDTO

    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: exercise.imageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                        ProgressView()
                    }
                    .aspectRatio(1, contentMode: .fit)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                case .failure:
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                    .aspectRatio(1, contentMode: .fit)
                @unknown default:
                    EmptyView()
                }
            }

            Text(exercise.name.capitalized)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(12)
        .background(.regularMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        ExploreView()
    }
}
