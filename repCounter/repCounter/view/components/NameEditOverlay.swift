import SwiftUI

struct NameEditOverlay: View {
    
    let title: String
    var onCancel: () -> Void
    var onSave:   ()   -> Void
    @Binding var isPresented: Bool
    @Binding var name: String
    
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        if isPresented {
            GeometryReader { geo in
                // width ~ 2/3, height ~ 1/3 of screen size
                let boxW = geo.size.width * 0.66
                let boxH = geo.size.width * 0.38 // minimal height for content
                
                ZStack {
                    // Dimmer
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { handleCancle() }
                    
                    // dialogue-card
                    VStack(spacing: 14) {
                        Text(title)
                            .font(.headline)
                        
                        // textfield
                        TextField("Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .focused($isFieldFocused)
                            .onSubmit { handleSafe() }
                        
                        // buttons
                        HStack(spacing: 24) {
                            Button("", systemImage: "x.circle") {
                                handleCancle()
                            }
                            .tint(.red)
                            
                            Button("", systemImage: "checkmark.circle") {
                                handleSafe()
                            }
                            .tint(.green)
                            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderedProminent)
                        .font(.title3)
                    }
                    .padding(16)
                    .frame(width: boxW, height: boxH, alignment: .top)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(radius: 20)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityAddTraits(.isModal)
                    .onAppear { isFieldFocused = true }
                }
            }
            .animation(.snappy, value: isPresented)
        }
    }
    
    // MARK: - helper functions
    
    private func handleSafe() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else{
            return
        }
        onSave()
        isPresented = false
    }
    
    private func handleCancle() {
        onCancel()
        isPresented = false
    }
}

#Preview {
    @Previewable
    @State var isPresented = true
    @Previewable
    @State var name = "Test Name"

    return NameEditOverlay(
        title: "Edit name",
        onCancel: { },
        onSave: { },
        isPresented: $isPresented,
        name: $name
    )
}
