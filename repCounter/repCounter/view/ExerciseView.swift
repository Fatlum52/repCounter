import SwiftUI
import SwiftData

struct ExerciseView: View {

    @Bindable var trainingSession: TrainingSession
    @Environment(\.modelContext) private var modelContext

    @State private var isAddingExercise: Bool = false
    @State private var isEditorPresented: Bool = false
    @State private var editingExercise: Exercise? = nil
    @State private var draftName: String = ""
    @FocusState private var isNewExerciseFocused: Bool

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button {
                        isAddingExercise.toggle()
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    Text("Add Exercise")
                }
                .font(.title2)
                .padding(.top, 10)

                if isAddingExercise {
                    TextField("Add Exercise", text: $draftName)
                        .onSubmit(addExercise)
                        .padding(15)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        .focused($isNewExerciseFocused)
                        .onAppear { isNewExerciseFocused = true }
                }

                if !trainingSession.exercises.isEmpty {
                    List {
                        ForEach(trainingSession.exercises) { exercise in
                            NavigationLink {
                                ExerciseDetailView(exercise: exercise)
                            } label: {
                                ExerciseRow(exercise: exercise)
                            }
#if os(iOS)
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    editingExercise = exercise
                                    isEditorPresented = true
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteExercise(exercise)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
#elseif os(macOS)
                            .contextMenu {
                                Button {
                                    editingExercise = exercise
                                    isEditorPresented = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    deleteExercise(exercise)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
#endif
                        }
                    }
                    .listStyle(.plain)
                } else {
                    Text("No exercises yet")
                        .foregroundStyle(.secondary)
                        .padding(.top, 3)
                }
            }
            .navigationTitle(trainingSession.name + " - " + trainingSession.formattedDate)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .overlay {
                if let exercise = editingExercise {
                    NameEditOverlay(
                        title: "Edit exercise name",
                        onCancel: cancelEdit,
                        onSave: { saveEdit(exercise: exercise) },
                        isPresented: $isEditorPresented,
                        name: Binding(
                            get: { exercise.name },
                            set: { exercise.name = $0 }
                        )
                    )
                }
            }
        }
    }
    
    ////////////////// HELPER FUNCTION //////////////////

    private func cancelEdit() {
        isEditorPresented = false
        editingExercise = nil
    }

    private func saveEdit(exercise: Exercise) {
        cancelEdit()
    }

    private func addExercise() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isAddingExercise = false

        let newExercise = Exercise(trimmed)
        modelContext.insert(newExercise)
        trainingSession.exercises.append(newExercise)

        draftName = ""
    }

    private func deleteExercise(_ exercise: Exercise) {
        trainingSession.exercises.removeAll { $0.id == exercise.id }
        modelContext.delete(exercise)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TrainingSession.self, Exercise.self, configurations: config)

    let session = TrainingSession(name: "Push Day")
    let exercise = Exercise("Bench Press")
    session.exercises.append(exercise)

    container.mainContext.insert(session)
    container.mainContext.insert(exercise)

    return ExerciseView(trainingSession: session)
        .modelContainer(container)
}
