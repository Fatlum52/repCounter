import SwiftUI

extension View {
    func limitedListHeight(maxItems: Int = 4, rowHeight: CGFloat = 47) -> some View {
        self.frame(maxHeight: CGFloat(maxItems) * rowHeight)
    }
}
