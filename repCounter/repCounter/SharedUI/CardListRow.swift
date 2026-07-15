import SwiftUI

extension View {
    /// Shared list-row chrome for card-style rows: no separator, symmetric vertical
    /// insets, clear background. Replaces the repeated three-modifier block.
    func cardListRow() -> some View {
        self
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            .listRowBackground(Color.clear)
    }

    /// Trailing swipe with a destructive Delete and an optional Edit action.
    /// Pass `onEdit: nil` for delete-only rows.
    func editDeleteSwipe(
        onEdit: (() -> Void)? = nil,
        onDelete: @escaping () -> Void
    ) -> some View {
        swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)

            if let onEdit {
                Button("Edit", systemImage: "pencil", action: onEdit)
                    .tint(.blue)
            }
        }
    }
}
