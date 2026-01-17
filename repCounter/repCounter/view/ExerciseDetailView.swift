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
    @State private var selectedItem: PhotosPickerItem? // holds the selected Photo item
    @State private var showPhotoLibrary: Bool = false // control photo library picker visibility
    @State private var selectedImage: UIImage? // holds the loaded image (for camera)
    @State private var selectedVideoURL: URL? // holds the video URL (for camera)
    @State private var showingCamera: Bool = false // control camera sheet visibility
    @State private var cameraMode: CameraMode = .photo
#elseif os(macOS)
    @State private var showFilePicker: Bool = false
#endif
    @State private var showMediaGallery: Bool = false
    @State private var showNotesSheet: Bool = false
    
    var body: some View {
        VStack {
            
            // Set Card
            SetCardStyle(
                exercise: exercise,
                focusedSetID: $focusedSetID,
                onAddSet: {
                    addSet()
                },
                onDeleteSet: { id in
                    deleteSet(id: id)
                },
                repsBinding: { id in
                    repsBinding(for: id)
                }
            )
            .padding(.horizontal)
            
            Divider()
                .padding(.vertical, 8)
            
            // Notes Button
            Button("Notes", systemImage: "list.bullet.clipboard") {
                showNotesSheet = true
            }
            
            // Media Button
            Menu {
#if os(iOS)
                Button("Select Media", systemImage: "photo.badge.plus") {
                    showPhotoLibrary = true
                }
                Button("Take Photo", systemImage: "camera") {
                    cameraMode = .photo
                    showingCamera = true
                }
                Button("Record Video", systemImage: "video") {
                    cameraMode = .video
                    showingCamera = true
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
            selection: $selectedItem,
            matching: .any(of: [.images, .videos]),
            photoLibrary: .shared()
        )
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            
            Task {
                // Reset previous selection
                selectedImage = nil
                selectedVideoURL = nil
                
                // Try to load as image first
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    // Save image to documents
                    let fileName = "exercise_\(exercise.id)_\(UUID().uuidString).jpg"
                    if FileManagerHelper.saveImageToDocuments(image: image, fileName: fileName) != nil {
                        await MainActor.run {
                            let mediaItem = Exercise.MediaItem(fileName: fileName, fileType: .image)
                            exercise.mediaItems.append(mediaItem)
                        }
                    }
                    return
                }
                
                // Try to load as video
                if let videoData = try? await newItem.loadTransferable(type: Movie.self) {
                    let fileName = "exercise_\(exercise.id)_\(UUID().uuidString).mp4"
                    if let savedURL = await FileManagerHelper.saveVideoToDocuments(videoURL: videoData.url, fileName: fileName) {
                        await MainActor.run {
                            let mediaItem = Exercise.MediaItem(fileName: savedURL.lastPathComponent, fileType: .video)
                            exercise.mediaItems.append(mediaItem)
                        }
                    }
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
        .sheet(isPresented: $showNotesSheet) {
            NotesSheetView(notes: $exercise.notes)
        }
#if os(iOS)
        .sheet(isPresented: $showingCamera) {
            CameraView(
                image: $selectedImage,
                videoURL: $selectedVideoURL,
                mode: cameraMode,
                onImageCaptured: { image in
                    saveCameraImage(image)
                    selectedImage = nil // Reset after saving
                },
                onVideoCaptured: { videoURL in
                    saveCameraVideo(videoURL)
                    selectedVideoURL = nil // Reset after saving
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
    
    private func addSet() -> Exercise.ExerciseSet.ID? {
        let newIndex = exercise.sets.count + 1
        let newSet = Exercise.ExerciseSet("Set \(newIndex)")
        
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
    
#if os(iOS)
    private func saveCameraImage(_ image: UIImage) {
        Task { @MainActor in
            let fileName = "exercise_\(exercise.id)_\(UUID().uuidString).jpg"
            if FileManagerHelper.saveImageToDocuments(image: image, fileName: fileName) != nil {
                let mediaItem = Exercise.MediaItem(fileName: fileName, fileType: .image)
                exercise.mediaItems.append(mediaItem)
            }
        }
    }
    
    private func saveCameraVideo(_ videoURL: URL) {
        Task { @MainActor in
            let fileName = "exercise_\(exercise.id)_\(UUID().uuidString).mp4"
            if let savedURL = await FileManagerHelper.saveVideoToDocuments(videoURL: videoURL, fileName: fileName) {
                let mediaItem = Exercise.MediaItem(fileName: savedURL.lastPathComponent, fileType: .video)
                exercise.mediaItems.append(mediaItem)
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
