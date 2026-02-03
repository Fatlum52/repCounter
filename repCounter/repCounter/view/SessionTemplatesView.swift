import SwiftUI
import SwiftData

struct SessionTemplatesView: View {
    
    // MARK: - Environment & Data
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var sessionTemplates: [SessionTemplate]
    @Query private var exerciseTemplates: [ExerciseTemplate]
    
    // MARK: - State
    @State private var newTemplateName: String = ""
    @State private var showEditSheet: Bool = false
    @State private var showAddSheet: Bool = false
    @State private var editingTemplate: SessionTemplate?
    @State private var editingName: String = ""
    @State private var editingExerciseNames: [String] = []
    @State private var showExerciseTemplatePicker: Bool = false
    
    var body: some View {
        ZStack {
            Background()
            
            VStack(spacing: 0) {
                // Add Button Section
                addButtonSection
                
                // Templates List
                if !sessionTemplates.isEmpty {
                    templatesList
                } else {
                    emptyStateView
                }
                
                Spacer()
            }
        }
        .navigationTitle("Session Templates")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
#if os(macOS)
        .frame(minWidth: 500, minHeight: 300)
#endif
        .interactiveDismissDisabled(hasUnsavedChangesInInlineField)
        .sheet(isPresented: $showEditSheet) {
            editSheetContent
        }
        .sheet(isPresented: $showAddSheet) {
            addSheetContent
        }
    }
    
    // MARK: - Add Button Section
    private var addButtonSection: some View {
        VStack {
            InlineAddField(
                menuTitle: "Add Template",
                actionTitle: "New Template",
                placeholder: "Session template name",
                text: $newTemplateName,
                onAdd: { name in
                    addTemplate(name: name)
                },
                onCancel: {
                    newTemplateName = ""
                }
            )
        }
    }
    
    // MARK: - Templates List
    private var templatesList: some View {
#if os(macOS)
        List {
            ForEach(sessionTemplates) { template in
                templateRow(template)
                    .contextMenu {
                        Button {
                            editTemplate(template)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            deleteTemplate(template)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
#else
        List {
            ForEach(sessionTemplates) { template in
                templateRow(template)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            deleteTemplate(template)
                        }
                        
                        Button("Edit", systemImage: "pencil") {
                            editTemplate(template)
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
    
    // MARK: - Template Row
    @ViewBuilder
    private func templateRow(_ template: SessionTemplate) -> some View {
        CardStyle {
            VStack(alignment: .leading, spacing: 8) {
                Text(template.name)
                    .font(.headline)
                
                if !template.exerciseNames.isEmpty {
                    Text("\(template.exerciseNames.count) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        Text("No session templates yet")
            .foregroundStyle(.secondary)
            .padding(.top, 3)
    }
    
    // MARK: - Edit Sheet Content
    @ViewBuilder
    private var editSheetContent: some View {
        NavigationStack {
            ZStack {
                Background()
                
                VStack(spacing: 20) {
                    sessionEditView
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Edit Session Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showEditSheet = false
                        editingTemplate = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEdit()
                    }
                }
            }
            .overlay {
                if showExerciseTemplatePicker {
                    exerciseTemplatePickerOverlay
                }
            }
            .interactiveDismissDisabled(true)
        }
    }
    
    // MARK: - Add Sheet Content
    @ViewBuilder
    private var addSheetContent: some View {
        NavigationStack {
            ZStack {
                Background()
                
                VStack(spacing: 20) {
                    sessionEditView
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New Session Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddSheet = false
                        editingName = ""
                        editingExerciseNames = []
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAdd()
                    }
                }
            }
            .overlay {
                if showExerciseTemplatePicker {
                    exerciseTemplatePickerOverlay
                }
            }
            .interactiveDismissDisabled(true)
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
                
                ScrollView {
                    VStack(spacing: 8) {
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
                    }
                }
                .frame(maxHeight: 300)
                
                HStack {
                    Button("Add Exercise", systemImage: "plus") {
                        editingExerciseNames.append("")
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        showExerciseTemplatePicker = true
                    } label: {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "list.bullet")
                                .frame(width: 20, alignment: .center)

                            Text("Add from Templates")
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    // MARK: - Exercise Template Picker Overlay
    @ViewBuilder
    private var exerciseTemplatePickerOverlay: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showExerciseTemplatePicker = false
                }
            
            // Picker content
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Select Exercise Templates")
                            .font(.headline)
                            .padding()
                        Spacer()
                        Button {
                            showExerciseTemplatePicker = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                    
                    Divider()
                    
                    // List
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(exerciseTemplates) { template in
                                Button {
                                    // Add template name to exercises if not already present
                                    if !editingExerciseNames.contains(template.name) {
                                        editingExerciseNames.append(template.name)
                                    }
                                    showExerciseTemplatePicker = false
                                } label: {
                                    CardStyle {
                                        Text(template.name)
                                            .font(.headline)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
#if os(iOS)
                    .frame(maxHeight: 400)
#elseif os(macOS)
                    .frame(minWidth: 600, minHeight: 500, maxHeight: 600)
#endif
                }
#if os(iOS)
                .background(Color(uiColor: .systemBackground))
#elseif os(macOS)
                .background(Color(nsColor: .windowBackgroundColor))
#endif
                .cornerRadius(16)
                .padding()
                .shadow(radius: 10)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Helper Functions
    private var hasUnsavedChangesInInlineField: Bool {
        !newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addTemplate(name: String) {
        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finalName.isEmpty else { return }
        
        // Open add sheet with pre-filled name
        editingName = finalName
        editingExerciseNames = []
        showAddSheet = true
    }
    
    private func editTemplate(_ template: SessionTemplate) {
        editingTemplate = template
        editingName = template.name
        editingExerciseNames = template.exerciseNames
        showEditSheet = true
    }
    
    private func saveEdit() {
        if let template = editingTemplate {
            template.name = editingName
            template.exerciseNames = editingExerciseNames.filter { !$0.isEmpty }
        }
        showEditSheet = false
        editingTemplate = nil
        editingName = ""
        editingExerciseNames = []
    }
    
    private func saveAdd() {
        let filteredExercises = editingExerciseNames.filter { !$0.isEmpty }
        SessionTemplateStore.shared.addTemplate(
            name: editingName,
            exercises: filteredExercises,
            in: modelContext
        )
        showAddSheet = false
        editingName = ""
        editingExerciseNames = []
    }
    
    private func deleteTemplate(_ template: SessionTemplate) {
        SessionTemplateStore.shared.removeTemplate(template, in: modelContext)
    }
}

#Preview {
    //SessionTemplatesView()
}
