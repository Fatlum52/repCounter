import SwiftUI
import SwiftData

struct TrainingSessionView: View {

    @Environment(\.modelContext) private var modelContext

    // Daten kommen jetzt aus SwiftData, nicht mehr aus @State
    @Query(sort: \TrainingSession.date, order: .reverse)
    private var trainingList: [TrainingSession]

    @State private var isAddingSession = false
    @State private var newSessionName = ""
    @FocusState private var isEditFieldFocused: Bool

    @State private var isEditorPresented = false
    @State private var editingSession: TrainingSession?
    @State private var editingName = ""
    @State private var selectedSessionID: UUID?

    var body: some View {
        NavigationSplitView {
            VStack {
                AddButtonCircle(title: "Add Training Session") {
                    isAddingSession.toggle()
                }

                if isAddingSession {
                    TextField("Add Training", text: $newSessionName)
                        .onSubmit(addSession)
                        .padding(15)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        .focused($isEditFieldFocused)
                        .onAppear { isEditFieldFocused = true }
                }

                if !trainingList.isEmpty {
                    List(selection: $selectedSessionID) {
                        ForEach(trainingList) { training in
                            NavigationLink(value: training.id) {
                                HStack {
                                    Text(training.name).font(.title2)
                                    Spacer()
                                    Text(training.formattedDate)
                                }
                            }
                            .tag(training.id)
#if os(iOS)
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    editingSession = training
                                    editingName = training.name
                                    isEditorPresented = true
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteSession(training)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
#elseif os(macOS)
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
#endif
                        }
                    }
                    .listStyle(.plain)
                } else {
                    Text("No trainings yet")
                        .foregroundStyle(.secondary)
                        .padding(.top, 3)
                }
            }
#if os(iOS)
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
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
        } detail: {
            if let selectedID = selectedSessionID,
               let selectedSession = trainingList.first(where: { $0.id == selectedID }) {
                NavigationStack {
                    ExerciseView(trainingSession: selectedSession)
                }
            } else if let firstSession = trainingList.first {
                NavigationStack {
                    ExerciseView(trainingSession: firstSession)
                }
            } else {
                Text("Select a training session")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    ////////////////// HELPER FUNCTION //////////////////

    private func addSession() {
        let name = newSessionName.isEmpty ? "Training Session" : newSessionName
        let newTraining = TrainingSession(name: name)
        modelContext.insert(newTraining)

        newSessionName = ""
        isAddingSession = false
    }

    private func deleteSession(_ session: TrainingSession) {
        // Wenn die gelöschte Session gerade ausgewählt ist, Auswahl zurücksetzen
        if selectedSessionID == session.id {
            selectedSessionID = nil
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
