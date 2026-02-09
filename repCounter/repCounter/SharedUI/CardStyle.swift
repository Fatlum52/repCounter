import SwiftUI

struct CardStyle<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .padding()  // Internal padding for content
            .background(.regularMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
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
