import SwiftUI
import SwiftData

struct ExerciseView: View {
    
    // MARK: - Data & Environment
    @Bindable var trainingSession: Session
    @Environment(\.modelContext) private var modelContext
    
#if os(macOS)
    @Binding var selectedExercise: Exercise?
#else
    @State private var selectedExercise: Exercise? = nil
#endif
    
    // MARK: - State
    @State private var isEditorPresented: Bool = false
    @State private var editingExercise: Exercise? = nil
    @State private var showLibraryPicker: Bool = false

    // MARK: - Computed Properties
    private var sortedExercises: [Exercise] {
        trainingSession.exerciseList.sorted(by: { $0.order < $1.order })
    }
    
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
            .sheet(isPresented: $showLibraryPicker) {
                NavigationStack {
                    ExerciseLibraryPicker(
                        onPick: { definition in
                            SessionStore.shared.addExercise(definition, to: trainingSession, in: modelContext)
                            showLibraryPicker = false
                        },
                        onCancel: { showLibraryPicker = false }
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
                
                if !trainingSession.exerciseList.isEmpty {
                    exercisesList
                } else {
                    emptyStateView
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Add Button Section
    private var addButtonSection: some View {
        Button("Add Exercise", systemImage: "plus.circle") {
            showLibraryPicker = true
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .foregroundStyle(.white)
    }
    
    // MARK: - Exercises List
    private var exercisesList: some View {
#if os(macOS)
        List(selection: $selectedExercise) {
            ForEach(sortedExercises) { exercise in
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
        List {
            ForEach(sortedExercises) { exercise in
                NavigationLink {
                    ExerciseDetailView(exercise: exercise)
                } label: {
                    ExerciseCard(exercise: exercise)
                }
                .editDeleteSwipe(
                    onEdit: {
                        editingExercise = exercise
                        isEditorPresented = true
                    },
                    onDelete: { deleteExercise(exercise) }
                )
                .cardListRow()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
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
        Button("Edit", systemImage: "pencil") {
            editingExercise = exercise
            isEditorPresented = true
        }
        
        Button("Delete", systemImage: "trash", role: .destructive) {
            deleteExercise(exercise)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        EmptyStateView("No exercises yet")
    }
    
    // MARK: - Helper functions
    private func deleteExercise(_ exercise: Exercise) {
        SessionStore.shared.remove(exercise, in: modelContext)
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
    let container = try! ModelContainer(for: Session.self, Exercise.self, configurations: config)
    
    let session = Session(name: "Push Day")
    let exercise = Exercise("Bench Press")
    exercise.session = session

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
