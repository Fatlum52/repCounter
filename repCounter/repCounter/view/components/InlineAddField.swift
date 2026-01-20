import SwiftUI

struct InlineAddField: View {
    
    @State private var menuName:String = ""
    @State private var buttonName:String = ""
    @State private var textFieldPlaceholder:String = ""
    @State private var name:String = ""
    @State private var isAdding = false
    @FocusState private var isFieldFocused: Bool
    
    var onDissmissAdding: () -> Void
    var onAdd: () -> Void
    
    
    var body: some View {
        
        Menu(menuName, systemImage: "plus.circle") {
            
            Button(buttonName) {
                isAdding.toggle()
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
                TextField(textFieldPlaceholder, text: $name)
                    .onSubmit(handleAdd)
                    .padding(15)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .focused($isFieldFocused)
                    .onAppear { isFieldFocused = true }
                
                Button("Cancel", systemImage: "x.circle") {
                    handleDissmissAdding()
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
                .padding(.trailing)
            }
            .padding(.horizontal)
        }
        
        
        
    }
    
    private func handleDissmissAdding() {
        onDissmissAdding()
    }
    
    private func handleAdd() {
        onAdd()
    }
}

