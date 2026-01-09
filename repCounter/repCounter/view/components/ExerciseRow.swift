import SwiftUI
import SwiftData

struct ExerciseRow: View {
    
    @Bindable var exercise: Exercise
    
    var body: some View {
        HStack {
            Text(exercise.name)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("\(exercise.totalReps) Reps")
                .foregroundStyle(.secondary)
                .font(.title3)
        }
        .font(.title2)
        .contentShape(Rectangle())
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Exercise.self, configurations: config)
    let exercise = Exercise("Pullup")
    
    ExerciseRow(exercise: exercise)
        .modelContainer(container)
}
