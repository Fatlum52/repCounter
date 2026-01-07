import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
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
                        if let image = FileManagerHelper.loadImageFromDocuments(fileName: item.fileName) {
                            Button {
                                selectedMediaItem = item
                            } label: {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(8)
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
                
                if let image = FileManagerHelper.loadImageFromDocuments(fileName: mediaItem.fileName) {
                    image
                        .resizable()
                        .scaledToFit()
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

