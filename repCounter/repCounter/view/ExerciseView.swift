import SwiftUI
import SwiftData

struct ExerciseView: View {
    
    // MARK: - Data & Environment
    @Bindable var trainingSession: TrainingSession
    @Environment(\.modelContext) private var modelContext
    
#if os(macOS)
    @Binding var selectedExercise: Exercise?
#else
    @State private var selectedExercise: Exercise? = nil
#endif
    
    // MARK: - State
    @State private var newExerciseName: String = ""
    @State private var isEditorPresented: Bool = false
    @State private var editingExercise: Exercise? = nil
    @State private var showTemplates: Bool = false
    
    // MARK: - Templates Query
    @Query private var userTemplates: [ExerciseTemplate]
    
    // MARK: - Body
    var body: some View {
        exerciseListContent
#if os(iOS)
            .navigationTitle(trainingSession.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
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
                NavigationStack {
                    TemplateSheetView(
                        templates: allTemplates,  // Defaults + User
                        title: "Exercise Templates",
                        onSelect: { name in addExercise(named: name) }
                    )
                }
            }
    }
    
    // MARK: - Exercise List Content
    private var exerciseListContent: some View {
        ZStack {
            Background()
            
            VStack(spacing: 0) {
                addButtonSection
                
                if !trainingSession.exercises.isEmpty {
                    exercisesList
                } else {
                    emptyStateView
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Add Button Section with Textfield
    private var addButtonSection: some View {
        InlineAddField(
            menuTitle: "Add Exercise",
            actionTitle: "New Exercise",
            placeholder: "Name of the exercise",
            text: $newExerciseName,
            onAdd: addExercise,
            onSelectFromLibrary: {
                showTemplates = true
            },
            onCancel: { }
        )
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
        .background(Color.clear)
        .scrollContentBackground(.hidden)
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
    
    // MARK: - Templates
    private var allTemplates: [String] {
        // Defaults (hardcoded) + User-Templates (aus SwiftData)
        let defaults = ExerciseTemplateStore.defaultTemplateNames
        let userNames = userTemplates.map { $0.name }
        return defaults + userNames
    }
    
    // MARK: - Helper functions
    private func addExercise(named name: String) {
        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finalName.isEmpty else { return }
        
        let newExercise = Exercise(finalName)
        modelContext.insert(newExercise)
        trainingSession.exercises.append(newExercise)
    }
    
    private func deleteExercise(_ exercise: Exercise) {
        FileManagerHelper.deleteMediaFiles(for: exercise)
        trainingSession.exercises.removeAll { $0.id == exercise.id }
        modelContext.delete(exercise)
    }
    
    private func cancelEdit() {
        isEditorPresented = false
        editingExercise = nil
    }
    
    private func saveEdit(exercise: Exercise) {
        cancelEdit()
    }
}

// MARK: - Preview
#Preview {
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
