import SwiftUI
import SwiftData

struct TrainingSessionCard: View {
    
    let trainingSession: TrainingSession
    
    var body: some View {
        CardStyle {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Name and Date
                HStack {
                    Text(trainingSession.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(trainingSession.formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Exercises List
                if !trainingSession.exercises.isEmpty {
                    VStack(alignment: .leading) {
                        ForEach(Array(trainingSession.exercises.sorted(by: { $0.order > $1.order }).enumerated()), id: \.element.id) { index, exercise in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(exercise.name)
                                        .font(.body)
                                    Spacer()
                                    Text("\(exercise.totalReps) Reps")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                if index < trainingSession.exercises.count - 1 {
                                    Divider()
                                }
                            }
                            .padding(4)
                        }
                    }
                    .padding(.top, 4)
                } else {
                    Text("No exercises yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TrainingSession.self, Exercise.self, configurations: config)
    
    let session = TrainingSession(name: "Push Day")
    let exercise1 = Exercise("Bench Press")
    exercise1.sets = [
        Exercise.ExerciseSet("Set 1"),
        Exercise.ExerciseSet("Set 2")
    ]
    exercise1.sets[0].reps = 10
    exercise1.sets[1].reps = 8
    
    let exercise2 = Exercise("Pushup")
    exercise2.sets = [Exercise.ExerciseSet("Set 1")]
    exercise2.sets[0].reps = 20
    
    session.exercises = [exercise1, exercise2]
    
    return ScrollView {
        VStack(spacing: 16) {
            TrainingSessionCard(trainingSession: session)
        }
        .padding()
    }
    .modelContainer(container)
}
