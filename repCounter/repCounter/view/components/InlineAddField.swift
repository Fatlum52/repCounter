import SwiftUI

struct InlineAddField: View {
    
    // config
    let menuTitle:String
    let actionTitle:String
    let placeholder:String
    
    // data
    @Binding var text:String
    
    // UI-State
    @State private var isAdding = false
    @FocusState private var isFocused: Bool
    
    // actions
    var onAdd: (String) -> Void
    var onCancel: () -> Void
    
    
    var body: some View {
        
        Menu(menuTitle, systemImage: "plus.circle") {
            
            Button(actionTitle) {
                isAdding = true
            }
            
            Button("From Library") {
                //showTemplates = true
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .foregroundStyle(.white)
        
        if isAdding {
            HStack {
                TextField(placeholder, text: $text)
                    .onSubmit {
                        handleAdd()
                    }
                    .padding(15)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .focused($isFocused)
                    .onAppear { isFocused = true }
                
                Button("Cancel", systemImage: "x.circle") {
                    handleCancel()
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
                .padding(.trailing)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - helper functions
    
    private func handleAdd() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        onAdd(trimmed)
        reset()
    }
    
    private func handleCancel() {
        reset()
        onCancel()
    }
    
    private func reset() {
        isFocused = false
        isAdding = false
        text = ""
    }
}

