import SwiftUI
import SwiftData

struct TrainingSessionView: View {
    
    // MARK: - Environment & Data
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrainingSession.date, order: .reverse)
    private var trainingList: [TrainingSession]
    
    // MARK: - Add / Edit State
    
    @State private var isAddingSession = false
    @State private var newSessionName = ""
    @FocusState private var isEditFieldFocused: Bool
    @State private var isEditorPresented = false
    @State private var editingSession: TrainingSession?
    @State private var editingName = ""
    
    // MARK: - Selection State
    
    @State private var selectedSession: TrainingSession?
    @State private var selectedExercise: Exercise?
    
    // MARK: - Body
    
    var body: some View {
#if os(macOS)
        NavigationSplitView {
            // Sidebar: Sessions
            sessionListContent
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 350)
        } content: {
            // Content: Exercises
            if let session = selectedSession ?? trainingList.first {
                ExerciseView(
                    trainingSession: session,
                    selectedExercise: $selectedExercise
                )
            } else {
                Text("Select a training session")
                    .foregroundStyle(.secondary)
            }
        } detail: {
            // Detail: ExerciseDetailView
            if let exercise = selectedExercise {
                ExerciseDetailView(exercise: exercise)
            } else {
                Text("Select an exercise")
                    .foregroundStyle(.secondary)
            }
        }
#else
        // iOS: Simple NavigationStack
        NavigationStack {
            sessionListContent
        }
#endif
    }
    
    // MARK: - Session List Content (Root)
    
    private var sessionListContent: some View {
        VStack(spacing: 0) {
            addButtonSection
            
            if !trainingList.isEmpty {
                sessionsList
            } else {
                emptyStateView
            }
            
            Spacer()
        }
#if os(iOS)
        .navigationTitle("Training Sessions")
        .navigationBarTitleDisplayMode(.inline)
#endif
        .overlay {
            NameEditOverlay(
                title: "Edit Session name",
                onCancel: cancelEdit,
                onSave: saveEdit,
                isPresented: $isEditorPresented,
                name: $editingName
            )
        }
    }
    
    // MARK: - Add Button Section with Textfield
    
    private var addButtonSection: some View {
        VStack {
#if os(macOS)
            AddButtonCircle(title: "Add Training Session") {
                isAddingSession.toggle()
            }
            .padding(.top, 8)
            .padding(.bottom, 20)
            .padding(.horizontal, 8)
            
            if isAddingSession {
                addSessionTextField
                    .padding(.horizontal, 8)
            }
#else
            Menu("Add Training Session", systemImage: "plus.circle") {
                
                Button("New Training Session") {
                    isAddingSession.toggle()
                }
                
                Button("From Library") {
                    //showTemplates = true
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .foregroundStyle(.white)
            
            if isAddingSession {
                HStack {
                    addSessionTextField
                    
                    Button("Cancel", systemImage: "x.circle") {
                        dismissAddSession()
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                    .padding(.trailing)
                }
                .padding(.horizontal)
            }
#endif
        }
    }
    
    // MARK: - Add Session TextField
    
    private var addSessionTextField: some View {
        TextField("Add Training", text: $newSessionName)
            .onSubmit(addSession)
            .padding(15)
            .textFieldStyle(.roundedBorder)
            .font(.title3)
            .focused($isEditFieldFocused)
            .onAppear { isEditFieldFocused = true }
    }
    
    // MARK: - Sessions List
    
    private var sessionsList: some View {
#if os(macOS)
        // macOS: Simple List in Sidebar
        List(trainingList, selection: Binding(
            get: { selectedSession?.id },
            set: { newID in
                selectedSession = trainingList.first { $0.id == newID }
                selectedExercise = nil // Reset exercise selection when session changes
            }
        )) { training in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(training.name)
                        .font(.headline)
                    Text(training.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !training.exercises.isEmpty {
                        Text("\(training.exercises.count) exercises")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 4)
            .tag(training.id)
            .contextMenu {
                Button {
                    editingSession = training
                    editingName = training.name
                    isEditorPresented = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    deleteSession(training)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
#else
        // iOS: Cards in ScrollView
        ScrollView {
            VStack(spacing: 16) {
                ForEach(trainingList) { training in
                    NavigationLink {
                        ExerciseView(trainingSession: training)
                    } label: {
                        TrainingSessionCard(trainingSession: training)
                    }
                    .contextMenu {
                        Button {
                            editingSession = training
                            editingName = training.name
                            isEditorPresented = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            deleteSession(training)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
#endif
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        Text("No trainings yet")
            .foregroundStyle(.secondary)
            .padding(.top, 3)
    }
    
    // MARK: - Helper Functions

    private func addSession() {
        let name = newSessionName.isEmpty ? "Training Session" : newSessionName
        let newTraining = TrainingSession(name: name)
        modelContext.insert(newTraining)

        newSessionName = ""
        isAddingSession = false
    }

    private func deleteSession(_ session: TrainingSession) {
        // Delete all media files for the exercises
        FileManagerHelper.deleteMediaFiles(for: session)
        
        // If the deleted session is currently selected, reset the selection
        if selectedSession?.id == session.id {
            selectedSession = nil
        }
        modelContext.delete(session)
    }

    private func cancelEdit() {
        withAnimation(.snappy) { isEditorPresented = false }
        editingSession = nil
    }

    private func saveEdit() {
        guard let session = editingSession else {
            cancelEdit()
            return
        }
        session.name = editingName
        cancelEdit()
    }
    
    private func dismissAddSession() {
        guard isAddingSession else { return }
        isEditFieldFocused = false
        isAddingSession = false
        newSessionName = ""
        
    }
}
