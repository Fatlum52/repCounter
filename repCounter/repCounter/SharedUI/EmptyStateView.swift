import SwiftUI

/// Shared placeholder for the repeated "No … yet" secondary texts.
struct EmptyStateView: View {
    let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .foregroundStyle(.secondary)
            .padding(.top, 3)
    }
}
