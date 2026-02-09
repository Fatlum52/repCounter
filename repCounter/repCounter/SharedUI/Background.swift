import SwiftUI

struct Background: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Base color - dark for dark mode, light for light mode
            if colorScheme == .dark {
                Color(red: 0.02, green: 0.02, blue: 0.04).ignoresSafeArea()
            } else {
                Color(red: 0.98, green: 0.98, blue: 0.99).ignoresSafeArea()
            }
            
            // Radial gradient - blue tint for dark mode, subtle warm tint for light mode
            RadialGradient(
                colors: colorScheme == .dark ? [
                    Color(red: 0.1, green: 0.12, blue: 0.3).opacity(0.4),
                    Color.clear
                ] : [
                    Color(red: 0.95, green: 0.96, blue: 1.0).opacity(0.6),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()
            
            // Linear gradient - dark fade for dark mode, light fade for light mode
            if colorScheme == .dark {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: Color(red: 0.05, green: 0.07, blue: 0.18).opacity(0.35), location: 0.55),
                        .init(color: Color(red: 0.03, green: 0.05, blue: 0.12).opacity(0.6), location: 0.75),
                        .init(color: Color(red: 0.01, green: 0.02, blue: 0.05), location: 0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            } else {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: Color(red: 0.96, green: 0.97, blue: 0.98), location: 0.5),
                        .init(color: Color(red: 0.92, green: 0.93, blue: 0.95), location: 0.8),
                        .init(color: Color(red: 0.88, green: 0.89, blue: 0.92), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        }
    }
}
