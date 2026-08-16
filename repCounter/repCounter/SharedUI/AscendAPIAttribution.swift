import SwiftUI

// Required by AscendAPI's free plan: their name has to appear on public-facing screens.
// Deliberately outside the empty state — that one disappears exactly when API data shows up.
struct AscendAPIAttribution: View {

    private let site = URL(string: "https://ascendapi.com")!

    var body: some View {
        Link(destination: site) {
            HStack(spacing: 4) {
                Text("Exercise data by")
                // Brand name: never translated, never auto-capitalised.
                Text(verbatim: "AscendAPI.com")
                    .underline()
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AscendAPIAttribution()
}
