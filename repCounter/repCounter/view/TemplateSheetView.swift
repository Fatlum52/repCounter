import SwiftUI

struct TemplateSheetView: View {
    
    let templates: [String]
    let title: String
    let onSelect: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        
        ScrollView {
            VStack(spacing: 12) {
                ForEach(templates, id: \.self) { name in
                    Button {
                        onSelect(name)
                        dismiss()
                    } label: {
                        CardStyle {
                            Text(name)
                                .font(.headline)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 16)  // Only vertical padding, horizontal is handled by CardStyle
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

#Preview {
    //TemplateSheetView()
}
