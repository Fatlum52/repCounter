import SwiftUI
import SwiftData

struct ExerciseRow: View {
    
    @Bindable var exercise: Exercise
    @FocusState private var isNumpadFocused: Bool
    
    // Binding, das totalReps anzeigt, aber quickReps schreibt
    private var totalRepsBinding: Binding<Int> {
        Binding(
            get: { exercise.totalReps },
            set: { newValue in
                let setsSum = exercise.sets.reduce(0) { $0 + $1.reps }
                let newQuick = max(0, newValue - setsSum)
                exercise.quickReps = newQuick
            }
        )
    }
    
    var body: some View {
        HStack {
            Text(exercise.name)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                
                HStack (spacing: 15) {
                    Button {
                        if exercise.quickReps > 0 {
                                    exercise.quickReps -= 1
                                }
                    } label: {
                        Image(systemName: "minus.rectangle.fill")
                    }

                    Button {
                        exercise.quickReps += 1
                    } label: {
                        Image(systemName: "plus.rectangle.fill")
                    }
                }
                .font(.title)
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                
                TextField("0", value: totalRepsBinding, format: .number)
#if os(iOS)
                .keyboardType(.numberPad)
                .focused($isNumpadFocused)
#endif
                .multilineTextAlignment(.trailing)
            }
        }
        .font(.title2)
        .contentShape(Rectangle())
#if os(iOS)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fertig") {
                    isNumpadFocused = false
                }
                .padding(.trailing, 8) // etwas Abstand vom Rand
            }
        }
#endif
    }
    
    ////////////////// HELPER FUNCTION //////////////////
    
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Exercise.self, configurations: config)
    let exercise = Exercise("Pullup")
    
    ExerciseRow(exercise: exercise)
        .modelContainer(container)
}

