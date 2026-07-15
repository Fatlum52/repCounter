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
    @State private var editingDefinitionIDs: [UUID] = []
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
                Button {
                    editTemplate(template)
                } label: {
                    templateRow(template)
                }
                .buttonStyle(.plain)
                .editDeleteSwipe(onDelete: { deleteTemplate(template) })
                .cardListRow()
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

                if !template.exerciseDefinitionIDs.isEmpty {
                    Text("\(template.exerciseDefinitionIDs.count) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        EmptyStateView("No session templates yet")
    }

    // MARK: - Session Sheet Content
    @ViewBuilder
    private var sessionSheetContent: some View {
        if showExerciseTemplatePicker {
            NavigationStack {
                ExerciseLibraryPicker(
                    onPick: { definition in
                        editingDefinitionIDs.append(definition.id)
                        showExerciseTemplatePicker = false
                    },
                    onCancel: { showExerciseTemplatePicker = false }
                )
            }
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

            // Exercises (resolved from definition ids, in stored order)
            VStack(alignment: .leading, spacing: 12) {
                Text("Exercises")
                    .font(.headline)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(editingDefinitionIDs.enumerated()), id: \.offset) { index, id in
                            HStack {
                                Text(name(forDefinitionID: id))
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Button(role: .destructive) {
                                    editingDefinitionIDs.remove(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)

                Button("Add Exercise", systemImage: "plus") {
                    showExerciseTemplatePicker = true
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Helper Functions
    private var hasUnsavedChangesInInlineField: Bool {
        !newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func name(forDefinitionID id: UUID) -> String {
        exerciseTemplates.first { $0.id == id }?.name ?? "(deleted)"
    }

    private func dismissSessionSheet() {
        showSessionSheet = false
        editingTemplate = nil
        editingName = ""
        editingDefinitionIDs = []
    }

    private func addTemplate(name: String) {
        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finalName.isEmpty else { return }
        editingTemplate = nil
        editingName = finalName
        editingDefinitionIDs = []
        showSessionSheet = true
    }

    private func editTemplate(_ template: SessionTemplate) {
        editingTemplate = template
        editingName = template.name
        editingDefinitionIDs = template.exerciseDefinitionIDs
        showSessionSheet = true
    }

    private func saveEdit() {
        if let template = editingTemplate {
            template.name = editingName
            template.exerciseDefinitionIDs = editingDefinitionIDs
        }
        dismissSessionSheet()
    }

    private func saveAdd() {
        SessionTemplateStore.shared.addTemplate(
            name: editingName,
            exerciseDefinitionIDs: editingDefinitionIDs,
            in: modelContext
        )
        dismissSessionSheet()
    }

    private func deleteTemplate(_ template: SessionTemplate) {
        SessionTemplateStore.shared.removeTemplate(template, in: modelContext)
    }
}
