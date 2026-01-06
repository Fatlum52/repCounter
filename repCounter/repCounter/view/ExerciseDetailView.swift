import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    
    @Bindable var exercise: Exercise
    @FocusState private var isNumpadFocused: Bool
    
    var body: some View {
        VStack {
            // Titel of Sets
            Text("Sets")
                .underline()
                .font(.title2)
            // Add Set-Button
            HStack {
                Button {
                    addSet()
                } label: {
                    Image(systemName: "plus.circle")
                }
                Text("Add Set")
            }
            
            List {
                if exercise.quickReps > 0 {
                    HStack {
                        Text("Manual Count")
                        Spacer()
                        Text("\(exercise.quickReps)")
                    }
                }
                ForEach(exercise.sets.indices, id: \.self) { index in
                    HStack {
                        Text("Set \(index + 1)")
                        TextField(
                            "0",
                            value: Binding(
                                get: { exercise.sets[index].reps },
                                set: { exercise.sets[index].reps = $0 }
                            ),
                            format: .number
                        )
#if os(iOS)
                        .keyboardType(.numberPad)
                        .focused($isNumpadFocused)
#endif
                        .multilineTextAlignment(.trailing)
                        
                        Text("Reps")
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteSet(exercise.sets[index])
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(exercise.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fertig") {
                    isNumpadFocused = false
                }
                .padding(.trailing, 8)
            }
        }
#endif
    }
    
    ////////////////// HELPER FUNCTION //////////////////
    
    private func addSet() {
        let newIndex = exercise.sets.count + 1
        exercise.sets.append(Exercise.ExerciseSet("Set \(newIndex)"))
    }
    
    private func deleteSet(_ set: Exercise.ExerciseSet) {
        exercise.sets.removeAll { $0.id == set.id }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Exercise.self, configurations: config)
    
    // Modelle erstellen und befüllen (außerhalb des View-Builders)
    let exercise = Exercise("Pullup")
    exercise.quickReps = 5
    exercise.sets.append(Exercise.ExerciseSet("Set 1"))
    
    // Optional: In den In-Memory-Kontext einfügen
    container.mainContext.insert(exercise)
    
    return ExerciseDetailView(exercise: exercise)
        .modelContainer(container)
}
