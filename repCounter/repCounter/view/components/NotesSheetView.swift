import SwiftUI

struct NotesSheetView: View {
    
    @Bindable var exercise: Exercise
    
    var body: some View {
        
        Text("Hello World")
        
        VStack {
            HStack {
                Text("Notes")
                    .font(.headline)
                Spacer()
                Text("Auto-Save")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            TextEditor(text: $exercise.notes)
                .frame(minHeight: 100)
                .padding(8)
                .background(.regularMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        
    }
}

#Preview {
    //NotesSheetView()
}
