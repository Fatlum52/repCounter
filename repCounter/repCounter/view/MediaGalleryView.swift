import SwiftUI
#if os(iOS)
import UIKit
import AVKit
import AVFoundation
#elseif os(macOS)
import AppKit
import AVKit
import AVFoundation
#endif

struct MediaGalleryView: View {
    @Bindable var exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMediaItem: Exercise.MediaItem?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 8)
                ], spacing: 8) {
                    ForEach(exercise.mediaItems) { item in
                        Button {
                            selectedMediaItem = item
                        } label: {
                            ZStack {
                                // Image
                                if item.fileType == .image,
                                   let image = FileManagerHelper.loadImageFromDocuments(fileName: item.fileName) {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(8)
                                }
                                // Video thumbnail
                                else if item.fileType == .video,
                                        let videoURL = FileManagerHelper.getVideoURL(fileName: item.fileName) {
                                    VideoThumbnailView(videoURL: videoURL)
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(8)
                                } else {
                                    // Placeholder
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(8)
                                }
                                
                                // Video indicator
                                if item.fileType == .video {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .shadow(radius: 3)
                                }
                            }
                        }
#if os(macOS)
                        .buttonStyle(.plain)
#endif
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteMedia(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Media")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedMediaItem) { item in
                FullscreenMediaView(mediaItem: item)
            }
        }
    }
    
    private func deleteMedia(_ item: Exercise.MediaItem) {
        FileManagerHelper.deleteFileFromDocuments(fileName: item.fileName)
        exercise.mediaItems.removeAll { $0.id == item.id }
    }
}

struct FullscreenMediaView: View {
    let mediaItem: Exercise.MediaItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if mediaItem.fileType == .image,
                   let image = FileManagerHelper.loadImageFromDocuments(fileName: mediaItem.fileName) {
                    image
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                } else if mediaItem.fileType == .video,
                          let videoURL = FileManagerHelper.getVideoURL(fileName: mediaItem.fileName) {
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .ignoresSafeArea()
                }
            }
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
#if os(iOS)
                    .foregroundColor(.white)
#endif
                }
            }
        }
    }
}

struct VideoThumbnailView: View {
    let videoURL: URL
    @State private var thumbnail: Image?
    
    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                thumbnail
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
        }
        .task {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        let asset = AVURLAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        Task {
            do {
                let cgImage = try await imageGenerator.image(at: CMTime.zero).image
#if os(iOS)
                let uiImage = UIImage(cgImage: cgImage)
                await MainActor.run {
                    thumbnail = Image(uiImage: uiImage)
                }
#elseif os(macOS)
                let nsImage = NSImage(cgImage: cgImage, size: .zero)
                await MainActor.run {
                    thumbnail = Image(nsImage: nsImage)
                }
#endif
            } catch {
                print("Error generating thumbnail: \(error)")
            }
        }
    }
}

