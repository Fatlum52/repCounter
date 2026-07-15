import SwiftUI

/// The shared card surface: material fill + rounded corners + stroke + optional shadow.
/// Single source for the `.background(.regularMaterial).cornerRadius().overlay(stroke).shadow()`
/// pattern that used to be duplicated across cards, sections and the pagination bar.
struct CardSurface: ViewModifier {
    var cornerRadius: CGFloat = 12
    var isHighlighted: Bool = false
    var accent: Color = Color(red: 1.0, green: 0.35, blue: 0.10)
    var strokeColor: Color = Color.gray.opacity(0.3)
    var lineWidth: CGFloat = 1.5
    var shadow: Bool = true

    func body(content: Content) -> some View {
        content
            .background(.regularMaterial)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(isHighlighted ? accent : strokeColor,
                            lineWidth: isHighlighted ? 2.0 : lineWidth)
            )
            .shadow(color: shadow ? Color.black.opacity(0.1) : .clear,
                    radius: shadow ? 8 : 0, x: 0, y: shadow ? 2 : 0)
    }
}

extension View {
    func cardSurface(
        cornerRadius: CGFloat = 12,
        isHighlighted: Bool = false,
        accent: Color = Color(red: 1.0, green: 0.35, blue: 0.10),
        strokeColor: Color = Color.gray.opacity(0.3),
        lineWidth: CGFloat = 1.5,
        shadow: Bool = true
    ) -> some View {
        modifier(CardSurface(
            cornerRadius: cornerRadius,
            isHighlighted: isHighlighted,
            accent: accent,
            strokeColor: strokeColor,
            lineWidth: lineWidth,
            shadow: shadow
        ))
    }
}
