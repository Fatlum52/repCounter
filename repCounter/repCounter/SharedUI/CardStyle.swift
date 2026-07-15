import SwiftUI

struct CardStyle<Content: View>: View {
    var isHighlighted: Bool = false
    let content: Content

    init(isHighlighted: Bool = false, @ViewBuilder content: () -> Content) {
        self.isHighlighted = isHighlighted
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .padding()  // Internal padding for content
            .cardSurface(isHighlighted: isHighlighted)
            .padding(.horizontal, 16)  // External padding/margin - consistent everywhere
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            CardStyle {
                VStack(alignment: .leading) {
                    Text("Card Title")
                        .font(.headline)
                    Text("Card Content")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 16)
    }
}
