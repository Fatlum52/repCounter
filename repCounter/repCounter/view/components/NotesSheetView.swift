import SwiftUI

struct NotesSheetView: View {
    
    @Binding var notes: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        
        NavigationStack {
            VStack {
                TextEditor(text: $notes)
                    .padding(8)
                    .background(.regularMaterial)
                    .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Notes")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        
    }
}

#Preview {
    NotesSheetView(notes: .constant("Sample notes text"))
}
