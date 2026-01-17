import SwiftUI
import SwiftData

struct ExerciseView: View {

    @Bindable var trainingSession: TrainingSession
    @Environment(\.modelContext) private var modelContext
    
#if os(macOS)
    @Binding var selectedExercise: Exercise?
#else
    @State private var selectedExercise: Exercise? = nil
#endif

    @State private var isAddingExercise: Bool = false
    @State private var isEditorPresented: Bool = false
    @State private var editingExercise: Exercise? = nil
    @State private var draftName: String = ""
    @FocusState private var isNewExerciseFocused: Bool

    var body: some View {
        exerciseListContent
#if os(iOS)
            .navigationTitle(trainingSession.name)
            .navigationBarTitleDisplayMode(.inline)
#else
            .navigationTitle(trainingSession.name + " - " + trainingSession.formattedDate)
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
    
    // MARK: - Exercise List Content
    
    private var exerciseListContent: some View {
        VStack(spacing: 0) {
#if os(macOS)
            // macOS: Add Button with padding
            VStack {
                AddButtonCircle(title: "Add Exercise") {
                    isAddingExercise.toggle()
                }
                .padding(.top, 8)
                .padding(.horizontal, 8)
                
                if isAddingExercise {
                    TextField("Add Exercise", text: $draftName)
                        .onSubmit(addExercise)
                        .padding(15)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        .focused($isNewExerciseFocused)
                        .onAppear { isNewExerciseFocused = true }
                        .padding(.horizontal, 8)
                }
            }
            
            if !trainingSession.exercises.isEmpty {
                // macOS: Simple List with selection
                List(selection: $selectedExercise) {
                    ForEach(trainingSession.exercises) { exercise in
                        HStack {
                            Text(exercise.name)
                                .font(.headline)
                            Spacer()
                            Text("\(exercise.totalReps) Reps")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .tag(exercise)
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
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            } else {
                Text("No exercises yet")
                    .foregroundStyle(.secondary)
                    .padding(.top, 3)
            }
#else
            // iOS: Add Button
            AddButtonCircle(title: "Add Exercise") {
                isAddingExercise.toggle()
            }

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
                // iOS: Cards in ScrollView
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(trainingSession.exercises) { exercise in
                            NavigationLink {
                                ExerciseDetailView(exercise: exercise)
                            } label: {
                                ExerciseCard(exercise: exercise)
                            }
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
                        }
                    }
                    .padding()
                }
            } else {
                Text("No exercises yet")
                    .foregroundStyle(.secondary)
                    .padding(.top, 3)
            }
#endif
            
            Spacer()
        }
    }
    
    // MARK: - Helper Functions

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
        // Delete all media files for the exercise
        FileManagerHelper.deleteMediaFiles(for: exercise)
        
        trainingSession.exercises.removeAll { $0.id == exercise.id }
        modelContext.delete(exercise)
    }
}

#Preview {
    ExerciseViewPreview()
}

struct ExerciseViewPreview: View {
    var body: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: TrainingSession.self, Exercise.self, configurations: config)

        let session = TrainingSession(name: "Push Day")
        let exercise = Exercise("Bench Press")
        session.exercises.append(exercise)

        container.mainContext.insert(session)
        container.mainContext.insert(exercise)

        return NavigationStack {
#if os(macOS)
            ExerciseView(trainingSession: session, selectedExercise: .constant(nil))
#else
            ExerciseView(trainingSession: session)
#endif
        }
        .modelContainer(container)
    }
}
