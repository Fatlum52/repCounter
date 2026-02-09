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
    @State private var showSessionSheet: Bool = false
    @State private var editingTemplate: SessionTemplate?
    @State private var editingName: String = ""
    @State private var editingExerciseNames: [String] = []
    @State private var showExerciseTemplatePicker: Bool = false
    
    var body: some View {
        ZStack {
            Background()
            
            VStack {
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
        .sheet(isPresented: $showSessionSheet) {
            sessionSheetContent
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
    
    // MARK: - Session Sheet Content
    @ViewBuilder
    private var sessionSheetContent: some View {
        if showExerciseTemplatePicker {
            exerciseTemplatePicker
        } else {
            NavigationStack {
                ZStack {
                    Background()
                    VStack(spacing: 20) {
                        sessionEditView
                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle("Session Template")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismissSessionSheet()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if editingTemplate != nil {
                                saveEdit()
                            } else {
                                saveAdd()
                            }
                        }
                    }
                }
                .interactiveDismissDisabled(true)
            }
        }
    }

    /// Picker as sheet
    @ViewBuilder
    private var exerciseTemplatePicker: some View {
        ZStack {
            Group {
#if os(iOS)
                Color(uiColor: .systemBackground)
#elseif os(macOS)
                Color(nsColor: .windowBackgroundColor)
#endif
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Select Exercise Templates")
                        .font(.headline)
                    Spacer()
                    Button("Done") {
                        showExerciseTemplatePicker = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider()

                // list of exercises to pick
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(exerciseTemplates) { template in
                            Button {
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
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.visible)

                Divider()

                // footer
                Button("Close") {
                    showExerciseTemplatePicker = false
                }
                .buttonStyle(.bordered)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
#if os(iOS)
            .background(Color(uiColor: .systemBackground))
#elseif os(macOS)
            .background(Color(nsColor: .windowBackgroundColor))
#endif
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
    
    // MARK: - Helper Functions
    private var hasUnsavedChangesInInlineField: Bool {
        !newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func dismissSessionSheet() {
        showSessionSheet = false
        editingTemplate = nil
        editingName = ""
        editingExerciseNames = []
    }
    
    private func addTemplate(name: String) {
        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finalName.isEmpty else { return }
        editingTemplate = nil
        editingName = finalName
        editingExerciseNames = []
        showSessionSheet = true
    }
    
    private func editTemplate(_ template: SessionTemplate) {
        editingTemplate = template
        editingName = template.name
        editingExerciseNames = template.exerciseNames
        showSessionSheet = true
    }
    
    private func saveEdit() {
        if let template = editingTemplate {
            template.name = editingName
            template.exerciseNames = editingExerciseNames.filter { !$0.isEmpty }
        }
        dismissSessionSheet()
    }
    
    private func saveAdd() {
        let filteredExercises = editingExerciseNames.filter { !$0.isEmpty }
        SessionTemplateStore.shared.addTemplate(
            name: editingName,
            exercises: filteredExercises,
            in: modelContext
        )
        dismissSessionSheet()
    }
    
    private func deleteTemplate(_ template: SessionTemplate) {
        SessionTemplateStore.shared.removeTemplate(template, in: modelContext)
    }
}
