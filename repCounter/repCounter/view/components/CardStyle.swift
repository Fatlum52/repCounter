import SwiftUI

struct CardStyle<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
#if os(iOS)
            .frame(maxWidth: .infinity)
            .frame(width: UIScreen.main.bounds.width * 0.9)
#else
            // macOS: fill available width, let parent control size
            .frame(maxWidth: .infinity)
#endif
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    CardStyle {
        VStack(alignment: .leading) {
            Text("Card Title")
                .font(.headline)
            Text("Card Content")
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}
