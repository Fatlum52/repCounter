import SwiftUI
import SwiftData

struct ExerciseCard: View {
    @Bindable var exercise: Exercise
    
    var body: some View {
        CardStyle {
            HStack {
                Text(exercise.name)
                    .font(.title3)
                    .fontWeight(.medium)
                Spacer()
                Text("\(exercise.totalReps) Reps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
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
    exercise.sets[1].reps = 12
    
    return ScrollView {
        VStack(spacing: 16) {
            ExerciseCard(exercise: exercise)
        }
        .padding()
    }
    .modelContainer(container)
}
