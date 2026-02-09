import SwiftUI
import SwiftData
#if os(iOS)
import PhotosUI
#elseif os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

struct ExerciseDetailView: View {

    @Bindable var exercise: Exercise
    @FocusState private var focusedField: SetFocusField?

#if os(iOS)
    @State private var selectedItem: PhotosPickerItem?
    @State private var showPhotoLibrary = false
#elseif os(macOS)
    @State private var showFilePicker = false
#endif
    @State private var showMediaGallery = false
    @State private var showNotesSheet = false

    var body: some View {
        ZStack {
            Background()

            ScrollView {
                VStack(spacing: 20) {
                    statsHeader
                    setsSection
                    notesSection
                    mediaSection
                }
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(exercise.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .photosPicker(
            isPresented: $showPhotoLibrary,
            selection: $selectedItem,
            matching: .any(of: [.images, .videos]),
            photoLibrary: .shared()
        )
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task { await importMedia(from: newItem) }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
#elseif os(macOS)
        .onChange(of: showFilePicker) { _, isShowing in
            if isShowing { selectImageFromFile() }
        }
#endif
        .sheet(isPresented: $showMediaGallery) {
            MediaGalleryView(exercise: exercise)
        }
        .sheet(isPresented: $showNotesSheet) {
            NotesSheetView(notes: $exercise.notes)
        }
    }

    // MARK: - Stats Header
    private var statsHeader: some View {
        HStack(spacing: 16) {
            statBadge(
                value: "\(exercise.sets.count)",
                label: "Sets",
                icon: "number"
            )
            statBadge(
                value: "\(exercise.totalReps)",
                label: "Total Reps",
                icon: "flame.fill"
            )
            statBadge(
                value: "\(exercise.totalWeight) kg",
                label: "Volume",
                icon: "scalemass.fill"
            )
        }
        .padding(.horizontal, 16)
    }

    private func statBadge(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    // MARK: - Sets Section
    private var setsSection: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack {
                Text("SET")
                    .frame(width: 50, alignment: .leading)
                Spacer()
                Text("KG")
                    .frame(width: 70, alignment: .center)
                Spacer()
                Text("REPS")
                    .frame(width: 70, alignment: .center)
                // Space for delete button
                Color.clear.frame(width: 32)
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // Set rows
            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                setRow(index: index, set: set)

                if index < exercise.sets.count - 1 {
                    Divider()
                        .padding(.horizontal, 20)
                }
            }

            // Add set button
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    if let newID = addSet() {
#if os(iOS)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            focusedField = .reps(newID)
                        }
#endif
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Add Set")
                        .fontWeight(.medium)
                }
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
        }
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private func setRow(index: Int, set: Exercise.ExerciseSet) -> some View {
        HStack(spacing: 0) {
            // Set number
            Text("\(index + 1)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)

            Spacer()

            // Weight input
            TextField("0", value: setBinding(for: set.id, keyPath: \.weight), format: .number)
#if os(iOS)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .weight(set.id))
#endif
                .multilineTextAlignment(.center)
                .font(.title3)
                .fontWeight(.medium)
                .frame(width: 70, height: 40)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            Spacer()

            // Reps input
            TextField("0", value: setBinding(for: set.id, keyPath: \.reps), format: .number)
#if os(iOS)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .reps(set.id))
#endif
                .multilineTextAlignment(.center)
                .font(.title3)
                .fontWeight(.medium)
                .frame(width: 70, height: 40)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            // Delete button
            Button(role: .destructive) {
                withAnimation(.spring(duration: 0.3)) {
                    deleteSet(id: set.id)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary.opacity(0.5))
                    .font(.body)
            }
            .buttonStyle(.plain)
            .frame(width: 32)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Button {
            showNotesSheet = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.blue.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "note.text")
                        .font(.body)
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Notes")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    if exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Tap to add notes...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(notesPreview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(.regularMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    private var notesPreview: String {
        let trimmed = exercise.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 80 { return trimmed }
        return String(trimmed.prefix(80)) + "..."
    }

    // MARK: - Media Section

    private var mediaSection: some View {
        VStack(spacing: 12) {
            // Gallery button (if media exists)
            if !exercise.mediaItems.isEmpty {
                Button {
                    showMediaGallery = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.purple.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: "photo.stack")
                                .font(.body)
                                .foregroundStyle(.purple)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Media")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text("\(exercise.mediaItems.count) item\(exercise.mediaItems.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                    .background(.regularMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            // Add media button
            Button {
#if os(iOS)
                showPhotoLibrary = true
#elseif os(macOS)
                showFilePicker = true
#endif
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.green.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "plus.circle.fill")
                            .font(.body)
                            .foregroundStyle(.green)
                    }

                    Text(exercise.mediaItems.isEmpty ? "Add Media" : "Add More Media")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Spacer()
                }
                .padding(16)
                .background(.regularMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Data Helpers
    private func setBinding(
        for id: Exercise.ExerciseSet.ID,
        keyPath: WritableKeyPath<Exercise.ExerciseSet, Int>
    ) -> Binding<Int> {
        Binding(
            get: { exercise.sets.first { $0.id == id }?[keyPath: keyPath] ?? 0 },
            set: { newValue in
                guard let idx = exercise.sets.firstIndex(where: { $0.id == id }) else { return }
                var copy = exercise.sets
                copy[idx][keyPath: keyPath] = newValue
                exercise.sets = copy
            }
        )
    }

    @discardableResult
    private func addSet() -> Exercise.ExerciseSet.ID? {
        let newSet = Exercise.ExerciseSet("Set \(exercise.sets.count + 1)")
        var copy = exercise.sets
        copy.append(newSet)
        exercise.sets = copy
        return newSet.id
    }

    private func deleteSet(id: Exercise.ExerciseSet.ID) {
        var copy = exercise.sets
        copy.removeAll { $0.id == id }
        exercise.sets = copy
    }

}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Exercise.self, configurations: config)
    let exercise = Exercise("Bench Press")

    return NavigationStack {
        ExerciseDetailView(exercise: exercise)
            .modelContainer(container)
    }
}
