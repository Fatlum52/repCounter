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
                // Breite ~ 2/3, Höhe ~ 1/3 der Bildschirmbreite
                let boxW = geo.size.width * 0.66
                let boxH = max(geo.size.width * 0.33, 180) // Mindesthöhe für Inhalt

                ZStack {
                    // Dimmer
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { handleCancle() }

                    // Dialog-Karte
                    VStack(spacing: 14) {
                        Text(title)
                            .font(.headline)

                        TextField("Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .focused($isFieldFocused)
                            .onSubmit { handleSafe() }

                        Spacer()

                        HStack(spacing: 24) {
                            Button {
                                handleCancle()
                            } label: {
                                Label("Cancel", systemImage: "x.circle")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)

                            Button {
                                handleSafe()
                            } label: {
                                Label("Save", systemImage: "checkmark.arrow.trianglehead.clockwise")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
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
