import SwiftUI
import SwiftData

enum TemplateType {
    case exercise
    case session
}

struct TemplateSheetView: View {
    
    let templateType: TemplateType
    let defaultNames: [String]  // For exercise templates (defaults)
    let userTemplates: [Any]  // ExerciseTemplate or SessionTemplate
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
    @State private var editingDefaultName: String? = nil  // Track if editing a default template
    @State private var deletedDefaultNames: Set<String> = []  // Track deleted default templates
    
    // MARK: - Computed Properties
    private var allTemplates: [(name: String, isDefault: Bool, template: Any?)] {
        var result: [(name: String, isDefault: Bool, template: Any?)] = []
        
        // Add defaults first (only for exercises), excluding deleted ones
        if templateType == .exercise {
            for defaultName in defaultNames {
                if !deletedDefaultNames.contains(defaultName) {
                    result.append((name: defaultName, isDefault: true, template: nil))
                }
            }
        }
        
        // Add user templates
        for template in userTemplates {
            if let exerciseTemplate = template as? ExerciseTemplate {
                result.append((name: exerciseTemplate.name, isDefault: false, template: exerciseTemplate))
            } else if let sessionTemplate = template as? SessionTemplate {
                result.append((name: sessionTemplate.name, isDefault: false, template: sessionTemplate))
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
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if allowsEditing {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            deleteTemplate(item.template, defaultName: item.isDefault ? item.name : nil)
                        }
                        
                        Button("Edit", systemImage: "pencil") {
                            editTemplate(item.template, defaultName: item.isDefault ? item.name : nil)
                        }
                        .tint(.blue)
                    }
                }
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
        .overlay {
            if templateType == .exercise {
                NameEditOverlay(
                    title: "Edit Exercise Template",
                    onCancel: {
                        showNameEditOverlay = false
                        editingExerciseTemplate = nil
                        editingDefaultName = nil
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
    private func editTemplate(_ template: Any?, defaultName: String?) {
        if let defaultName = defaultName {
            // Editing a default template
            editingDefaultName = defaultName
            editingName = defaultName
            editingExerciseTemplate = nil
            editingSessionTemplate = nil
            
            if templateType == .exercise {
                // Use NameEditOverlay for exercise templates
                showNameEditOverlay = true
            } else {
                // Use sheet for session templates (needs exercises management)
                editingExerciseNames = []
                showEditSheet = true
            }
        } else if let template = template {
            // Editing an existing user template
            if let exerciseTemplate = template as? ExerciseTemplate {
                editingExerciseTemplate = exerciseTemplate
                editingName = exerciseTemplate.name
                editingDefaultName = nil
                showNameEditOverlay = true
            } else if let sessionTemplate = template as? SessionTemplate {
                editingSessionTemplate = sessionTemplate
                editingName = sessionTemplate.name
                editingExerciseNames = sessionTemplate.exerciseNames
                editingDefaultName = nil
                showEditSheet = true
            }
        }
    }
    
    private func saveExerciseEdit() {
        if let defaultName = editingDefaultName {
            // Saving a default template as a new user template
            ExerciseTemplateStore.shared.addTemplate(name: editingName, in: modelContext)
            // Hide the original default
            deletedDefaultNames.insert(defaultName)
            editingDefaultName = nil
        } else if let exerciseTemplate = editingExerciseTemplate {
            // Updating existing user template
            exerciseTemplate.name = editingName
        }
        showNameEditOverlay = false
    }
    
    private func saveEdit() {
        // This is only called for session templates now
        if let defaultName = editingDefaultName {
            // Saving a default template as a new user template
            SessionTemplateStore.shared.addTemplate(
                name: editingName,
                exercises: editingExerciseNames.filter { !$0.isEmpty },
                in: modelContext
            )
            // Hide the original default
            deletedDefaultNames.insert(defaultName)
            editingDefaultName = nil
        } else if let sessionTemplate = editingSessionTemplate {
            // Updating existing user template
            sessionTemplate.name = editingName
            sessionTemplate.exerciseNames = editingExerciseNames.filter { !$0.isEmpty }
        }
        showEditSheet = false
    }
    
    private func deleteTemplate(_ template: Any?, defaultName: String?) {
        if let defaultName = defaultName {
            // Deleting a default template - just hide it from the list
            deletedDefaultNames.insert(defaultName)
        } else if let template = template {
            // Deleting a user template from SwiftData
            if let exerciseTemplate = template as? ExerciseTemplate {
                ExerciseTemplateStore.shared.removeTemplate(exerciseTemplate, in: modelContext)
            } else if let sessionTemplate = template as? SessionTemplate {
                SessionTemplateStore.shared.removeTemplate(sessionTemplate, in: modelContext)
            }
        }
    }
}

#Preview {
    //TemplateSheetView()
}
