import SwiftUI
import SwiftData

struct SetCardStyle: View {
    
    @Bindable var exercise: Exercise
    @FocusState.Binding var focusedSetID: Exercise.ExerciseSet.ID?
    var onAddSet: () -> Exercise.ExerciseSet.ID?
    var onDeleteSet: (Exercise.ExerciseSet.ID) -> Void
    var repsBinding: (Exercise.ExerciseSet.ID) -> Binding<Int>
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack {
                Text("Set")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            
            // Sets List
            List {
                let rows = Array(exercise.sets.enumerated())
                ForEach(rows, id: \.element.id) { index, set in
                    let displayNumber = index + 1
                    
                    HStack {
                        Text("\(displayNumber). Set")
                            .font(.body)
                        Spacer()
                        TextField(
                            "0",
                            value: repsBinding(set.id),
                            format: .number
                        )
#if os(iOS)
                        .keyboardType(.numberPad)
                        .focused($focusedSetID, equals: set.id)
#endif
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        Text("reps")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
#if os(iOS)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            onDeleteSet(set.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
#elseif os(macOS)
                    .contextMenu {
                        Button(role: .destructive) {
                            onDeleteSet(set.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
#endif
                    .listRowSeparator(.visible)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }
                
                // Add Set Row
                HStack {
                    Spacer()
                    AddButtonCircle(title: "add Set", onAdd: {
                        if let newSetID = onAddSet() {
#if os(iOS)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                focusedSetID = newSetID
                            }
#endif
                        }
                    })
                    Spacer()
                }
                .padding(.vertical, 0)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(.regularMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    PreviewWrapper()
}

struct PreviewWrapper: View {
    @FocusState private var focusedSetID: Exercise.ExerciseSet.ID?
    @State private var exercise: Exercise = {
        let ex = Exercise("Pullup")
        var set1 = Exercise.ExerciseSet("Set 1")
        set1.reps = 10
        var set2 = Exercise.ExerciseSet("Set 2")
        set2.reps = 12
        ex.sets = [set1, set2] // Set 1 oben, Set 2 darunter
        return ex
    }()
    
    var body: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Exercise.self, configurations: config)
        
        SetCardStyle(
            exercise: exercise,
            focusedSetID: $focusedSetID,
            onAddSet: {
                let newSet = Exercise.ExerciseSet("Set \(exercise.sets.count + 1)")
                var copy = exercise.sets
                copy.append(newSet)
                exercise.sets = copy
                return newSet.id
            },
            onDeleteSet: { id in
                var copy = exercise.sets
                copy.removeAll { $0.id == id }
                exercise.sets = copy
            },
            repsBinding: { id in
                Binding(
                    get: { exercise.sets.first(where: { $0.id == id })?.reps ?? 0 },
                    set: { newValue in
                        guard let idx = exercise.sets.firstIndex(where: { $0.id == id }) else { return }
                        var copy = exercise.sets
                        copy[idx].reps = newValue
                        exercise.sets = copy
                    }
                )
            }
        )
        .modelContainer(container)
        .padding()
    }
}
