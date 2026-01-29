import SwiftUI
import SwiftData

struct TrainingSessionView: View {
    
    // MARK: - Environment & Data
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrainingSession.date, order: .reverse)
    private var trainingList: [TrainingSession]
    
    // MARK: - Add / Edit State
    @State private var newSessionName = ""
    @State private var isEditorPresented = false
    @State private var editingSession: TrainingSession?
    @State private var editingName = ""
    @State private var showTemplates: Bool = false
    
    // MARK: - Selection State
    @State private var selectedSession: TrainingSession?
    @State private var selectedExercise: Exercise?
    
    // MARK: - Templates Query
    @Query private var userTemplates: [SessionTemplate]
    
    // MARK: - Body
    var body: some View {
#if os(macOS)
        ZStack {
            Background()
            
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
        }
        .toolbarBackground(.hidden, for: .windowToolbar)
#else
        // iOS: Simple NavigationStack
        NavigationStack {
            sessionListContent
        }
#endif
    }
    
    // MARK: - Session List Content (Root)
    private var sessionListContent: some View {
        ZStack {
            Background()
            
            VStack(spacing: 0) {
                addButtonSection
                
                if !trainingList.isEmpty {
                    sessionsList
                } else {
                    emptyStateView
                }
                
                Spacer()
            }
        }
#if os(iOS)
        .navigationTitle("Training Sessions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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
        .sheet(isPresented: $showTemplates) {
            NavigationStack {
                TemplateSheetView(
                    templateType: .session,
                    userTemplates: userTemplates.map { $0 as Any },
                    title: "Session Templates",
                    onSelect: addSession(named:),
                    allowsEditing: false
                )
            }
        }
    }
    
    // MARK: - Add Button Section with Textfield
    private var addButtonSection: some View {
        VStack {
            InlineAddField(
                menuTitle: "Add Session",
                actionTitle: "New Session",
                placeholder: "Name of your Training Session",
                text: $newSessionName,
                onAdd: addSession,
                onSelectFromLibrary: {
                    showTemplates = true
                },
                onCancel: { newSessionName = "" }
            )
        }
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
        // iOS: Cards in List with Swipe Actions
        List {
            ForEach(trainingList) { training in
                NavigationLink {
                    ExerciseView(trainingSession: training)
                } label: {
                    TrainingSessionCard(trainingSession: training)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        deleteSession(training)
                    }
                    
                    Button("Edit", systemImage: "pencil") {
                        editingSession = training
                        editingName = training.name
                        isEditorPresented = true
                    }
                    .tint(.blue)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
#endif
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        Text("No trainings yet")
            .foregroundStyle(.secondary)
            .padding(.top, 3)
    }
    
    // MARK: - Helper Functions
    private func addSession(named name: String) {
        let finalName = name.isEmpty ? "Training Session" : name
        let newTraining = TrainingSession(name: finalName)
        modelContext.insert(newTraining)
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
}
