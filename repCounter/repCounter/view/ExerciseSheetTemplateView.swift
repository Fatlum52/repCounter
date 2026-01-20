import SwiftUI

struct ExerciseSheetTemplateView: View {
    
    let templates: [ExerciseTemplate]
    let onSelect: (ExerciseTemplate) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(templates) { template in
                    Button {
                        onSelect(template)
                        dismiss()
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
        .navigationTitle("Exercise Templates")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}
