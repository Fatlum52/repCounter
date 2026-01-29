import SwiftUI
import SwiftData

enum TemplateType {
    case exercise
    case session
}

struct TemplateSheetView: View {
    
    let templateType: TemplateType
    let userTemplates: [Any]  // ExerciseTemplate or SessionTemplate (includes defaults now)
    let title: String
    let onSelect: (String) -> Void
    let allowsEditing: Bool  // Whether templates can be edited/deleted (only true in LibraryView)
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Edit State
    @State private var showEditSheet: Bool = false
    @State private var showNameEditOverlay: Bool = false
    @State private var editingExerciseTemplate: ExerciseTemplate?
    @State private var editingSessionTemplate: SessionTemplate?
    @State private var editingName: String = ""
    @State private var editingExerciseNames: [String] = []
    
    // MARK: - Computed Properties
    private var allTemplates: [(name: String, template: Any)] {
        var result: [(name: String, template: Any)] = []
        
        // All templates are now in SwiftData (including defaults)
        for template in userTemplates {
            if let exerciseTemplate = template as? ExerciseTemplate {
                result.append((name: exerciseTemplate.name, template: exerciseTemplate))
            } else if let sessionTemplate = template as? SessionTemplate {
                result.append((name: sessionTemplate.name, template: sessionTemplate))
            }
        }
        
        return result
    }
    
    var body: some View {
        List {
            ForEach(allTemplates.indices, id: \.self) { index in
                let item = allTemplates[index]
                Button {
                    onSelect(item.name)
                    dismiss()
                } label: {
                    CardStyle {
                        Text(item.name)
                            .font(.headline)
                    }
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
                #if os(iOS)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if allowsEditing {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            deleteTemplate(item.template)
                        }
                        
                        Button("Edit", systemImage: "pencil") {
                            editTemplate(item.template)
                        }
                        .tint(.blue)
                    }
                }
                #elseif os(macOS)
                .contextMenu {
                    if allowsEditing {
                        Button("Edit", systemImage: "pencil") {
                            editTemplate(item.template)
                        }
                        
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            deleteTemplate(item.template)
                        }
                    }
                }
                #endif
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
#if os(macOS)
        .frame(minWidth: 500, minHeight: 300)
#endif
        .overlay {
            if templateType == .exercise {
                NameEditOverlay(
                    title: "Edit Exercise Template",
                    onCancel: {
                        showNameEditOverlay = false
                        editingExerciseTemplate = nil
                    },
                    onSave: {
                        saveExerciseEdit()
                    },
                    isPresented: $showNameEditOverlay,
                    name: $editingName
                )
            }
        }
        .sheet(isPresented: $showEditSheet) {
            editSheetContent
        }
    }
    
    // MARK: - Edit Sheet Content (only for Session Templates)
    @ViewBuilder
    private var editSheetContent: some View {
        NavigationStack {
            ZStack {
                Background()
                
                VStack(spacing: 20) {
                    sessionEditView
                }
                .padding()
            }
            .navigationTitle("Edit Session Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showEditSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEdit()
                    }
                }
            }
        }
    }
    
    // MARK: - Session Edit View
    private var sessionEditView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Name
            VStack(alignment: .leading, spacing: 12) {
                Text("Session Name")
                    .font(.headline)
                TextField("Session name", text: $editingName)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Exercises
            VStack(alignment: .leading, spacing: 12) {
                Text("Exercises")
                    .font(.headline)
                
                ForEach(Array(editingExerciseNames.enumerated()), id: \.offset) { index, exerciseName in
                    HStack {
                        TextField("Exercise name", text: Binding(
                            get: { editingExerciseNames[index] },
                            set: { editingExerciseNames[index] = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        
                        Button(role: .destructive) {
                            editingExerciseNames.remove(at: index)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Button("Add Exercise", systemImage: "plus") {
                    editingExerciseNames.append("")
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func editTemplate(_ template: Any) {
        if let exerciseTemplate = template as? ExerciseTemplate {
            editingExerciseTemplate = exerciseTemplate
            editingName = exerciseTemplate.name
            showNameEditOverlay = true
        } else if let sessionTemplate = template as? SessionTemplate {
            editingSessionTemplate = sessionTemplate
            editingName = sessionTemplate.name
            editingExerciseNames = sessionTemplate.exerciseNames
            showEditSheet = true
        }
    }
    
    private func saveExerciseEdit() {
        if let exerciseTemplate = editingExerciseTemplate {
            // Update existing template directly in SwiftData
            exerciseTemplate.name = editingName
        }
        showNameEditOverlay = false
    }
    
    private func saveEdit() {
        // This is only called for session templates
        if let sessionTemplate = editingSessionTemplate {
            // Update existing template directly in SwiftData
            sessionTemplate.name = editingName
            sessionTemplate.exerciseNames = editingExerciseNames.filter { !$0.isEmpty }
        }
        showEditSheet = false
    }
    
    private func deleteTemplate(_ template: Any) {
        // Delete template directly from SwiftData
        if let exerciseTemplate = template as? ExerciseTemplate {
            ExerciseTemplateStore.shared.removeTemplate(exerciseTemplate, in: modelContext)
        } else if let sessionTemplate = template as? SessionTemplate {
            SessionTemplateStore.shared.removeTemplate(sessionTemplate, in: modelContext)
        }
    }
}

#Preview {
    //TemplateSheetView()
}
