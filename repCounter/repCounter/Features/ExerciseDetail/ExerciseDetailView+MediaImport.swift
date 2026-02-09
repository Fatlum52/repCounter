import SwiftUI
#if os(iOS)
import PhotosUI
#elseif os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

// MARK: - Media Import
extension ExerciseDetailView {

#if os(iOS)
    func importMedia(from item: PhotosPickerItem) async {
        // Try image
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            let fileName = "exercise_\(exercise.id)_\(UUID().uuidString).jpg"
            if await FileManagerHelper.saveImageToDocuments(image: image, fileName: fileName) != nil {
                await MainActor.run {
                    exercise.mediaItems.append(
                        Exercise.MediaItem(fileName: fileName, fileType: .image)
                    )
                }
            }
            return
        }
        // Try video
        if let video = try? await item.loadTransferable(type: Movie.self) {
            let fileName = "exercise_\(exercise.id)_\(UUID().uuidString).mp4"
            if let savedURL = await FileManagerHelper.saveVideoToDocuments(videoURL: video.url, fileName: fileName) {
                await MainActor.run {
                    exercise.mediaItems.append(
                        Exercise.MediaItem(fileName: savedURL.lastPathComponent, fileType: .video)
                    )
                }
            }
        }
    }
#endif

#if os(macOS)
    func selectImageFromFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .image, .jpeg, .png, .gif, .heic,
            .movie, .mpeg4Movie, .quickTimeMovie
        ]
        panel.begin { response in
            if response == .OK {
                Task {
                    for url in panel.urls {
                        let ext = url.pathExtension.lowercased()
                        if ["mov", "mp4", "m4v"].contains(ext) {
                            let fileName = "exercise_\(exercise.id)_\(UUID().uuidString).mp4"
                            if let savedURL = await FileManagerHelper.saveVideoToDocuments(videoURL: url, fileName: fileName) {
                                await MainActor.run {
                                    exercise.mediaItems.append(
                                        Exercise.MediaItem(fileName: savedURL.lastPathComponent, fileType: .video)
                                    )
                                }
                            }
                        } else if let image = NSImage(contentsOf: url) {
                            let fileName = "exercise_\(exercise.id)_\(UUID().uuidString).jpg"
                            if await FileManagerHelper.saveImageToDocuments(image: image, fileName: fileName) != nil {
                                await MainActor.run {
                                    exercise.mediaItems.append(
                                        Exercise.MediaItem(fileName: fileName, fileType: .image)
                                    )
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
