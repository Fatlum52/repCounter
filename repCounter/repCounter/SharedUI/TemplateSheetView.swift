import SwiftUI
import SwiftData

struct TemplateSheetView: View {
    
    let templates: [String]  // Template names only (for selection)
    let title: LocalizedStringKey
    let onSelect: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
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
                .cardListRow()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
#if os(macOS)
        .frame(minWidth: 500, minHeight: 300)
#endif
    }
}

#Preview {
    //TemplateSheetView()
}
