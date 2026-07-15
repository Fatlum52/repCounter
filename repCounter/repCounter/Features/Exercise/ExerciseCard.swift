import SwiftUI
import SwiftData

struct ExerciseCard: View {
    @Bindable var exercise: Exercise

    var body: some View {
        CardStyle {
            VStack(alignment: .leading, spacing: 12) {
                // Header: name + media indicator
                HStack(alignment: .top, spacing: 8) {
                    Text(exercise.name)
                        .font(.title3)
                        .fontWeight(.medium)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    if !exercise.mediaItems.isEmpty {
                        Image(systemName: "photo.stack")
                            .font(.subheadline)
                            .foregroundStyle(.purple)
                    }
                }

                // Stats (only meaningful once sets exist)
                if exercise.sets.isEmpty {
                    Text("No sets yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 12) {
                        StatBadge(value: "\(exercise.sets.count)", label: "Sets", icon: "number")
                        StatBadge(value: "\(exercise.totalReps)", label: "Reps", icon: "flame.fill", color: .orange)
                        StatBadge(value: volume, label: "Volume", icon: "scalemass.fill")
                        StatBadge(value: bestSet, label: "Best", icon: "trophy.fill", color: .yellow)
                    }
                }
            }
        }
    }

    private var volume: String {
        exercise.totalWeight.formatted(.number.notation(.compactName).precision(.fractionLength(0...1)))
    }

    private var bestSet: String {
        exercise.bestSetWeight.formatted(.number.precision(.fractionLength(0...2)))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Exercise.self, configurations: config)

    let exercise = Exercise("Pullup")
    exercise.sets = [
        Exercise.ExerciseSet("Set 1"),
        Exercise.ExerciseSet("Set 2")
    ]
    exercise.sets[0].reps = 10
    exercise.sets[0].weight = 20
    exercise.sets[1].reps = 12
    exercise.sets[1].weight = 22.5

    let empty = Exercise("Plank")

    return ScrollView {
        VStack(spacing: 16) {
            ExerciseCard(exercise: exercise)
            ExerciseCard(exercise: empty)
        }
        .padding()
    }
    .modelContainer(container)
}
