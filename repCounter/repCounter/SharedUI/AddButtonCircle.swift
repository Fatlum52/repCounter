import SwiftUI

struct AddButtonCircle: View {

    let title: String
    let onAdd: () -> Void

    var body: some View {
        Button(title, systemImage: "plus.circle") {
            onAdd()
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .foregroundStyle(.white)
    }
}
