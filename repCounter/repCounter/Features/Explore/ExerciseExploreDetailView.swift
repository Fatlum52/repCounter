import SwiftUI
import SwiftData
import AVKit

struct ExerciseExploreDetailView: View {
    let exercise: ExerciseDTO
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var player: AVPlayer?
    @State private var fullExercise: ExerciseDTO?
    @State private var isLoadingDetails = false
    @State private var addedToLibrary = false

    private let apiClient = ExerciseAPIClient()

    private var detail: ExerciseDTO {
        fullExercise ?? exercise
    }

    var body: some View {
        ZStack {
            Background()

            ScrollView {
                VStack(spacing: 20) {
                    mediaSection
                    addToLibraryButton
                    infoSection
                    musclesSection
                    equipmentSection
                    instructionsSection
                }
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
        }
        .sensoryFeedback(.success, trigger: addedToLibrary)
        .navigationTitle(exercise.name.capitalized)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
#endif
        .task {
            await loadFullDetails()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func loadFullDetails() async {
        isLoadingDetails = true
        do {
            let fetched = try await apiClient.fetchExercise(id: exercise.exerciseId)
            await MainActor.run {
                fullExercise = fetched
                if let urlString = fetched.videoUrl,
                   let url = URL(string: urlString) {
                    player = AVPlayer(url: url)
                }
                isLoadingDetails = false
            }
        } catch {
            await MainActor.run {
                isLoadingDetails = false
            }
        }
    }

    // MARK: - Add to Library

    private var addToLibraryButton: some View {
        Button {
            ExerciseTemplateStore.shared.definition(named: detail.name, in: modelContext)
            addedToLibrary = true
        } label: {
            Label(
                addedToLibrary ? "Added to Library" : "Add to Library",
                systemImage: addedToLibrary ? "checkmark.circle.fill" : "plus.circle.fill"
            )
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(addedToLibrary ? .green : .accentColor)
        .disabled(addedToLibrary)
        .padding(.horizontal, 16)
    }

    // MARK: - Media

    private var mediaSection: some View {
        VStack(spacing: 12) {
            if let player {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                #if os(macOS)
                    .frame(maxHeight: 280)
                #endif
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
            } else if isLoadingDetails {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                    ProgressView()
                }
                .aspectRatio(16/9, contentMode: .fit)
                .padding(.horizontal, 16)
            } else if let imageUrlString = detail.imageUrl,
                      let imageURL = URL(string: imageUrlString) {
                exerciseImage(url: imageURL)
            }
        }
    }

    private func exerciseImage(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                    ProgressView()
                }
                .aspectRatio(1, contentMode: .fit)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(16)
            case .failure:
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
                .aspectRatio(1, contentMode: .fit)
            @unknown default:
                EmptyView()
            }
        }
        #if os(macOS)
        .frame(maxHeight: 300)
        #endif
        .padding(.horizontal, 16)
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !detail.bodyParts.isEmpty {
                infoRow(icon: "figure.stand", label: "Body Parts", color: .blue) {
                    tagFlow(items: detail.bodyParts, color: .blue)
                }
            }

            if !detail.targetMuscles.isEmpty {
                infoRow(icon: "flame.fill", label: "Target Muscles", color: .orange) {
                    tagFlow(items: detail.targetMuscles, color: .orange)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Muscles

    private var musclesSection: some View {
        Group {
            if !detail.secondaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    infoRow(icon: "bolt.fill", label: "Secondary Muscles", color: .purple) {
                        tagFlow(items: detail.secondaryMuscles, color: .purple)
                    }
                }
                .padding(16)
                .background(.regularMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Equipment

    private var equipmentSection: some View {
        Group {
            if !detail.equipments.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    infoRow(icon: "dumbbell.fill", label: "Equipment", color: .green) {
                        tagFlow(items: detail.equipments, color: .green)
                    }
                }
                .padding(16)
                .background(.regularMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        Group {
            if let instructions = detail.instructions, !instructions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "list.number")
                            .font(.body)
                            .foregroundStyle(.teal)
                        Text("Instructions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(instructions.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(.teal)
                                    .clipShape(Circle())

                                Text(step)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(16)
                .background(.regularMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Reusable Components

    private func infoRow<Content: View>(
        icon: String,
        label: LocalizedStringKey,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            content()
        }
    }

    private func tagFlow(items: [String], color: Color) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(color.opacity(0.12))
                    .foregroundStyle(color)
                    .cornerRadius(20)
            }
        }
    }
}

// MARK: - Flow Layout (wrapping horizontal layout)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
