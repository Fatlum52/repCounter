import SwiftUI

struct ExploreView: View {
    
    @State private var searchText = ""
    @State private var results: [ExerciseDTO] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasSearched = false
    
    private let apiClient = ExerciseAPIClient()
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            Background()
            
            VStack(spacing: 16) {
                // Search Bar
                searchBar
                
                // Content
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
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        results = []
                        hasSearched = false
                        errorMessage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(.regularMaterial)
            .cornerRadius(12)
            
            Button {
                performSearch()
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
                ForEach(results, id: \.exerciseId) { exercise in
                    ExerciseCardView(exercise: exercise)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
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
                performSearch()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Search Action
    private func performSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        hasSearched = true
        
        Task {
            do {
                let fetchedResults = try await apiClient.searchExercises(search: trimmed, limit: 10)
                await MainActor.run {
                    results = fetchedResults
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
}

// MARK: - Exercise Card View
struct ExerciseCardView: View {
    let exercise: ExerciseDTO
    
    var body: some View {
        VStack(spacing: 8) {
            // GIF Image
            AsyncImage(url: URL(string: exercise.gifUrl)) { phase in
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
            
            // Exercise Name
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
