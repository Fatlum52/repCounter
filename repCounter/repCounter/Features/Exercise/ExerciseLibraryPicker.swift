import SwiftUI
import SwiftData

// Picks or find-or-creates an `ExerciseTemplate`. Fully controlled — `onPick`/`onCancel` own
// dismissal — so it works both as a sheet and as inline sheet content.
struct ExerciseLibraryPicker: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExerciseTemplate.name) private var templates: [ExerciseTemplate]
    @State private var newName = ""

    let onPick: (ExerciseTemplate) -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Background()

            VStack(spacing: 0) {
                InlineAddField(
                    menuTitle: "Add to Library",
                    actionTitle: "New Exercise",
                    placeholder: "Exercise name",
                    text: $newName,
                    onAdd: { name in
                        let definition = ExerciseTemplateStore.shared.definition(named: name, in: modelContext)
                        onPick(definition)
                    },
                    onCancel: { newName = "" }
                )

                if templates.isEmpty {
                    EmptyStateView("No exercises in library yet")
                } else {
                    List {
                        ForEach(templates) { template in
                            Button {
                                onPick(template)
                            } label: {
                                CardStyle {
                                    HStack {
                                        Text(template.name)
                                            .font(.headline)
                                        Spacer()
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .cardListRow()
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }

                Spacer()
            }
        }
        .navigationTitle("Add Exercise")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { onCancel() }
            }
        }
#if os(macOS)
        .frame(minWidth: 500, minHeight: 300)
#endif
    }
}
