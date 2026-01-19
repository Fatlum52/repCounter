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
    @State private var showTemplates: Bool = false
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
            .sheet(isPresented: $showTemplates) {
                
            }
    }
    
    // MARK: - Exercise List Content
    
    private var exerciseListContent: some View {
        VStack(spacing: 0) {
            // Add Button Section
            addButtonSection
            
            // Exercise List or Empty State
            if !trainingSession.exercises.isEmpty {
                exercisesList
            } else {
                emptyStateView
            }
            
            Spacer()
        }
    }
    
    // MARK: - Add Button Section
    
    private var addButtonSection: some View {
        VStack {
#if os(macOS)
            AddButtonCircle(title: "Add Exercise") {
                isAddingExercise.toggle()
            }
            .padding(.top, 8)
            .padding(.horizontal, 8)
            
            if isAddingExercise {
                addExerciseTextField
                    .padding(.horizontal, 8)
            }
#else
            
            Menu("Add Exercise", systemImage: "plus.circle") {
                
                Button("New Exercise") {
                    isAddingExercise.toggle()
                }
                
                Button("From Library") {
                    showTemplates = true
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .foregroundStyle(.white)
            
            //AddButtonCircle(title: "Add Exercise") {
            //    isAddingExercise.toggle()
            //}

            if isAddingExercise {
                addExerciseTextField
            }
#endif
        }
    }
    
    private var addExerciseTextField: some View {
        TextField("Add Exercise", text: $draftName)
            .onSubmit(addExercise)
            .padding(15)
            .textFieldStyle(.roundedBorder)
            .font(.title3)
            .focused($isNewExerciseFocused)
            .onAppear { isNewExerciseFocused = true }
    }
    
    // MARK: - Exercises List
    
    private var exercisesList: some View {
#if os(macOS)
        List(selection: $selectedExercise) {
            ForEach(trainingSession.exercises) { exercise in
                exerciseRow(for: exercise)
                    .tag(exercise)
                    .contextMenu {
                        exerciseContextMenu(for: exercise)
                    }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
#else
        ScrollView {
            VStack(spacing: 16) {
                ForEach(trainingSession.exercises) { exercise in
                    NavigationLink {
                        ExerciseDetailView(exercise: exercise)
                    } label: {
                        ExerciseCard(exercise: exercise)
                    }
                    .contextMenu {
                        exerciseContextMenu(for: exercise)
                    }
                }
            }
            .padding()
        }
#endif
    }
    
    // MARK: - Exercise Row (macOS)
    
    @ViewBuilder
    private func exerciseRow(for exercise: Exercise) -> some View {
        HStack {
            Text(exercise.name)
                .font(.headline)
            Spacer()
            Text("\(exercise.totalReps) Reps")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func exerciseContextMenu(for exercise: Exercise) -> some View {
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
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        Text("No exercises yet")
            .foregroundStyle(.secondary)
            .padding(.top, 3)
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

// MARK: - Preview

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
