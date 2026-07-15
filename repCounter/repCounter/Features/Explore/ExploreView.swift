import SwiftUI

struct ExploreView: View {

    @State private var model: ExploreModel
    @State private var selectedExercise: ExerciseDTO?

#if os(iOS)
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    private static let pageSize = 10
#elseif os(macOS)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)
    private static let pageSize = 12
#endif

    init() {
        _model = State(initialValue: ExploreModel(pageSize: Self.pageSize))
    }

    var body: some View {
        ZStack {
            Background()

            VStack(spacing: 16) {
                searchBar

                if model.isLoading {
                    Spacer()
                    ProgressView("Searching...")
                        .progressViewStyle(.circular)
                    Spacer()
                } else if let error = model.errorMessage {
                    Spacer()
                    errorView(error)
                    Spacer()
                } else if model.results.isEmpty && model.hasSearched {
                    Spacer()
                    emptyStateView
                    Spacer()
                } else if !model.results.isEmpty {
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

                TextField("Search for exercises...", text: $model.searchText)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .onSubmit { Task { await model.performSearch() } }

                if !model.searchText.isEmpty {
                    Button {
                        model.clearSearch()
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
                Task { await model.performSearch() }
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Results Grid
    private var resultsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(model.results) { exercise in
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

    private var paginationBar: some View {
        HStack {
            Button {
                Task { await model.goToPreviousPage() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
            }
            .disabled(model.currentPage <= 1)

            Spacer()

            if model.totalResults > 0 {
                Text("Page \(model.currentPage) of \(model.totalPages)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task { await model.goToNextPage() }
            } label: {
                HStack(spacing: 6) {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
            }
            .disabled(!model.hasNextPage)
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .cardSurface(strokeColor: .clear, shadow: false)
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
                Task { await model.retryCurrentPage() }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding(.horizontal, 32)
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
        .cardSurface()
    }
}

#Preview {
    NavigationStack {
        ExploreView()
    }
}
