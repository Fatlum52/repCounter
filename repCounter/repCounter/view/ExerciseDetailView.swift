import SwiftUI
import SwiftData
import PhotosUI

struct ExerciseDetailView: View {

    @Bindable var exercise: Exercise
    @FocusState private var focusedSetID: Exercise.ExerciseSet.ID?
    @State private var showPhotoLibrary: Bool = false
    @State private var photosPickerItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []

    var body: some View {
        VStack {
            Text("Sets")
                .underline()
                .font(.title2)

            AddButtonCircle(title: "Add Set") {
                addSet()
            }

            List {
                // Manual count Row
                if exercise.quickReps > 0 {
                    HStack {
                        Text("Manual Count")
                        Spacer()
                        Text("\(exercise.quickReps) Reps")
                            .font(.body)
                    }
                }

                let rows = Array(exercise.sets.enumerated())

                ForEach(rows, id: \.element.id) { index, set in
                    let displayNumber = exercise.sets.count - index // Set 1 unten

#if os(iOS)
                    HStack {
                        Text("Set \(displayNumber)")
                        Spacer()
                        TextField(
                            "0",
                            value: repsBinding(for: set.id),
                            format: .number
                        )
                        .keyboardType(.numberPad)
                        .focused($focusedSetID, equals: set.id)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        Text("Reps")
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteSet(id: set.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
#elseif os(macOS)
                    // macOS: Formatierung wie Manual Count
                    HStack {
                        Text("Set \(displayNumber)")
                            .font(.title3)
                        Spacer()
                        TextField(
                            "0",
                            value: repsBinding(for: set.id),
                            format: .number
                        )
                        .font(.title3)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        Text("Reps")
                            .font(.title3)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteSet(id: set.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
#endif
                }
            }
            .listStyle(.plain)
            
            Divider()
                .padding(.vertical, 8)
            
            // Notes Area
            VStack {
                HStack {
                    Text("Notes")
                        .font(.headline)
                    Spacer()
                    Text("Auto-Save")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                TextEditor(text: $exercise.notes)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(.regularMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            // Media Button
            Menu {
                Button("Select Media", systemImage: "photo.badge.plus") {
                    // action
                    showPhotoLibrary = true
                }
                .onChange(of: photosPickerItems) { _, newItems in
                    guard !newItems.isEmpty else { return }
                    
                    Task {
#if os(iOS)
                        var loadedImages: [UIImage] = []
#endif
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self) {
#if os(iOS)
                                if let image = UIImage(data: data) {
                                    loadedImages.append(image)
                                }
#endif
                            }
                        }
                        await MainActor.run {
                            selectedImages.append(contentsOf: loadedImages)
                            photosPickerItems = [] // Reset for next selection
                        }
                    }
                }
                Button("Take Photo/Video", systemImage: "camera") {
                    // action
                }
                Button("Show Media", systemImage: "photo.stack") {
                    // action
                }
            } label: {
                Label("Media", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
        }
        .navigationTitle(exercise.name)
        .photosPicker(
            isPresented: $showPhotoLibrary,
            selection: $photosPickerItems,
            matching: .images
        )
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fertig") { focusedSetID = nil }
                    .padding(.trailing, 8)
            }
        }
#endif
    }

    ////////////////// HELPER FUNCTION //////////////////

    private func repsBinding(for id: Exercise.ExerciseSet.ID) -> Binding<Int> {
        Binding(
            get: {
                exercise.sets.first(where: { $0.id == id })?.reps ?? 0
            },
            set: { newValue in
                guard let idx = exercise.sets.firstIndex(where: { $0.id == id }) else { return }
                var copy = exercise.sets
                copy[idx].reps = newValue
                exercise.sets = copy
            }
        )
    }

    private func addSet() {
        let newIndex = exercise.sets.count + 1
        let newSet = Exercise.ExerciseSet("Set \(newIndex)")

        var copy = exercise.sets
        copy.insert(newSet, at: 0)
        exercise.sets = copy

#if os(iOS)
        DispatchQueue.main.async {
            focusedSetID = newSet.id
        }
#endif
    }

    private func deleteSet(id: Exercise.ExerciseSet.ID) {
        var copy = exercise.sets
        copy.removeAll { $0.id == id }
        exercise.sets = copy
    }
}
