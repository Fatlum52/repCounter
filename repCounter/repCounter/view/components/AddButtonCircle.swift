import SwiftUI

struct AddButtonCircle: View {
    
    let title: String
    var onAdd:   ()   -> Void
    
    var body: some View {
        
        HStack {
            Button(title, systemImage: "plus.circle") {
                handleAdd()
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .foregroundStyle(.white)
    }
    
    private func handleAdd() {
        onAdd()
    }
}
