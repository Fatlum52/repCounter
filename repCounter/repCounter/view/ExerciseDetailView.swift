import SwiftUI
import SwiftData
#if os(iOS)
import PhotosUI
#elseif os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

#if os(iOS)
struct Movie: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.documentsDirectory.appending(path: "\(UUID().uuidString).mov")
            if FileManager.default.fileExists(atPath: copy.path()) {
                try FileManager.default.removeItem(at: copy)
            }
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
    }
}
#endif

struct ExerciseDetailView: View {

    @Bindable var exercise: Exercise
    @FocusState private var focusedSetID: Exercise.ExerciseSet.ID?
#if os(iOS)
    @State private var showPhotoLibrary: Bool = false
    @State private var photosPickerItems: [PhotosPickerItem] = []
    @State private var showCamera: Bool = false
    @State private var cameraMode: CameraMode = .photo
#elseif os(macOS)
    @State private var showFilePicker: Bool = false
#endif
    @State private var showMediaGallery: Bool = false

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
#if os(iOS)
                Button("Select Media", systemImage: "photo.badge.plus") {
                    showPhotoLibrary = true
                }
                Button("Take Photo", systemImage: "camera") {
                    cameraMode = .photo
                    showCamera = true
                }
                Button("Record Video", systemImage: "video") {
                    cameraMode = .video
                    showCamera = true
                }
#elseif os(macOS)
                Button("Select Media", systemImage: "photo.badge.plus") {
                    showFilePicker = true
                }
#endif
                Button("Show Media", systemImage: "photo.stack") {
                    showMediaGallery = true
                }
            } label: {
                Label("Media", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
        }
        .navigationTitle(exercise.name)
#if os(iOS)
        .photosPicker(
            isPresented: $showPhotoLibrary,
            selection: $photosPickerItems,
            matching: .any(of: [.images, .videos])
        )
        .onChange(of: photosPickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            
            Task {
                for item in newItems {
                    // Check if it's a video
                    if let videoData = try? await item.loadTransferable(type: Movie.self) {
                        let fileName = "exercise_\(exercise.id)_\(UUID().uuidString).mp4"
                        if let savedURL = await FileManagerHelper.saveVideoToDocuments(videoURL: videoData.url, fileName: fileName) {
                            await MainActor.run {
                                let mediaItem = Exercise.MediaItem(fileName: savedURL.lastPathComponent, fileType: .video)
                                exercise.mediaItems.append(mediaItem)
                            }
                        }
                    } else if let data = try? await item.loadTransferable(type: Data.self) {
                        // It's an image
                        if let image = UIImage(data: data) {
                            await MainActor.run {
                                let fileName = "exercise_\(exercise.id)_\(UUID().uuidString).jpg"
                                if FileManagerHelper.saveImageToDocuments(image: image, fileName: fileName) != nil {
                                    let mediaItem = Exercise.MediaItem(fileName: fileName, fileType: .image)
                                    exercise.mediaItems.append(mediaItem)
                                }
                            }
                        }
                    }
                }
                await MainActor.run {
                    photosPickerItems = []
                }
            }
        }
#elseif os(macOS)
        .onChange(of: showFilePicker) { _, isShowing in
            if isShowing {
                selectImageFromFile()
            }
        }
#endif
        .sheet(isPresented: $showMediaGallery) {
            MediaGalleryView(exercise: exercise)
        }
#if os(iOS)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(
                mode: cameraMode,
                onImage: { image in
                    saveCameraImage(image)
                    showCamera = false
                },
                onVideo: { videoURL in
                    saveCameraVideo(videoURL)
                    showCamera = false
                },
                onCancel: {
                    showCamera = false
                }
            )
        }
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
    
#if os(iOS)
    private func saveCameraImage(_ image: UIImage) {
        let fileName = "exercise_\(exercise.id)_\(UUID().uuidString).jpg"
        if FileManagerHelper.saveImageToDocuments(image: image, fileName: fileName) != nil {
            let mediaItem = Exercise.MediaItem(fileName: fileName, fileType: .image)
            exercise.mediaItems.append(mediaItem)
        }
    }
    
    private func saveCameraVideo(_ videoURL: URL) {
        let fileName = "exercise_\(exercise.id)_\(UUID().uuidString).mp4"
        Task {
            if let savedURL = await FileManagerHelper.saveVideoToDocuments(videoURL: videoURL, fileName: fileName) {
                await MainActor.run {
                    let mediaItem = Exercise.MediaItem(fileName: savedURL.lastPathComponent, fileType: .video)
                    exercise.mediaItems.append(mediaItem)
                }
            }
        }
    }
#endif
    
#if os(macOS)
    private func selectImageFromFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image, .jpeg, .png, .gif, .heic, .movie, .mpeg4Movie, .quickTimeMovie]
        
        panel.begin { response in
            if response == .OK {
                Task {
                    for url in panel.urls {
                        // Check if it's a video
                        if url.pathExtension.lowercased() == "mov" || url.pathExtension.lowercased() == "mp4" || url.pathExtension.lowercased() == "m4v" {
                            let fileName = "exercise_\(exercise.id)_\(UUID().uuidString).mp4"
                            if let savedURL = await FileManagerHelper.saveVideoToDocuments(videoURL: url, fileName: fileName) {
                                await MainActor.run {
                                    let mediaItem = Exercise.MediaItem(fileName: savedURL.lastPathComponent, fileType: .video)
                                    exercise.mediaItems.append(mediaItem)
                                }
                            }
                        } else if let image = NSImage(contentsOf: url) {
                            // It's an image
                            let fileName = "exercise_\(exercise.id)_\(UUID().uuidString).jpg"
                            if FileManagerHelper.saveImageToDocuments(image: image, fileName: fileName) != nil {
                                await MainActor.run {
                                    let mediaItem = Exercise.MediaItem(fileName: fileName, fileType: .image)
                                    exercise.mediaItems.append(mediaItem)
                                }
                            }
                        }
                    }
                }
            }
            showFilePicker = false
        }
    }
#endif
}
