import SwiftUI
import SwiftData

struct ExerciseTemplatesView: View {
    
    // MARK: - Environment & Data
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var exerciseTemplates: [ExerciseTemplate]
    
    // MARK: - State
    @State private var newTemplateName: String = ""
    @State private var showNameEditOverlay: Bool = false
    @State private var editingTemplate: ExerciseTemplate?
    @State private var editingName: String = ""
    
    var body: some View {
        ZStack {
            Background()
            
            VStack(spacing: 0) {
                // Add Button Section
                addButtonSection
                
                // Templates List
                if !exerciseTemplates.isEmpty {
                    templatesList
                } else {
                    emptyStateView
                }
                
                Spacer()
            }
        }
        .navigationTitle("Exercise Templates")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
#if os(macOS)
        .frame(minWidth: 500, minHeight: 300)
#endif
        .overlay {
            NameEditOverlay(
                title: showNameEditOverlay && editingTemplate == nil ? "New Exercise Template" : "Edit Exercise Template",
                onCancel: {
                    showNameEditOverlay = false
                    editingTemplate = nil
                    editingName = ""
                },
                onSave: {
                    if let template = editingTemplate {
                        // Edit existing
                        template.name = editingName
                    } else {
                        // Create new
                        ExerciseTemplateStore.shared.addTemplate(name: editingName, in: modelContext)
                    }
                    showNameEditOverlay = false
                    editingTemplate = nil
                    editingName = ""
                },
                isPresented: $showNameEditOverlay,
                name: $editingName
            )
        }
    }
    
    // MARK: - Add Button Section
    private var addButtonSection: some View {
        VStack {
            InlineAddField(
                menuTitle: "Add Template",
                actionTitle: "New Template",
                placeholder: "Exercise template name",
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
            ForEach(exerciseTemplates) { template in
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
            ForEach(exerciseTemplates) { template in
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
    private func templateRow(_ template: ExerciseTemplate) -> some View {
        CardStyle {
            Text(template.name)
                .font(.headline)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        Text("No exercise templates yet")
            .foregroundStyle(.secondary)
            .padding(.top, 3)
    }
    
    // MARK: - Helper Functions
    private func addTemplate(name: String) {
        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !finalName.isEmpty else { return }
        
        ExerciseTemplateStore.shared.addTemplate(name: finalName, in: modelContext)
    }
    
    private func editTemplate(_ template: ExerciseTemplate) {
        editingTemplate = template
        editingName = template.name
        showNameEditOverlay = true
    }
    
    private func deleteTemplate(_ template: ExerciseTemplate) {
        ExerciseTemplateStore.shared.removeTemplate(template, in: modelContext)
    }
}

#Preview {
    //ExerciseTemplatesView()
}
