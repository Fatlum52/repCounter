import SwiftUI

struct AddButtonCircle: View {
    
    var onAdd:   ()   -> Void
    let title: String
    
    var body: some View {
        
        HStack {
            Button {
                handleAdd()
            } label: {
                Image(systemName: "plus.circle")
            }
            Text(title)
        }
        .font(.title2)
        .padding(.top, 10)
    }
    
    private func handleAdd() {
        onAdd()
    }
}
