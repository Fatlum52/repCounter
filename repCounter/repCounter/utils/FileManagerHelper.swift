import Foundation
import SwiftUI
#if os(iOS)
import UIKit
import AVFoundation
#elseif os(macOS)
import AppKit
import AVFoundation
#endif

class FileManagerHelper {
    static func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory,
                                in: .userDomainMask)[0]
    }
    
#if os(iOS)
    static func saveImageToDocuments(image: UIImage, fileName: String) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            return url
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    static func loadImageFromDocuments(fileName: String) -> Image? {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        guard let uiImage = UIImage(contentsOfFile: url.path) else { return nil }
        return Image(uiImage: uiImage)
    }
#elseif os(macOS)
    static func saveImageToDocuments(image: NSImage, fileName: String) -> URL? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let data = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            return nil
        }
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            return url
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    static func loadImageFromDocuments(fileName: String) -> Image? {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        guard let nsImage = NSImage(contentsOfFile: url.path) else { return nil }
        return Image(nsImage: nsImage)
    }
#endif
    
    static func deleteFileFromDocuments(fileName: String) {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
    
    // MARK: - Video Support
    
    static func saveVideoToDocuments(videoURL: URL, fileName: String) async -> URL? {
        let destinationURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        // If file already exists, delete it
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        
        // Compress and save video
        return await compressAndSaveVideo(sourceURL: videoURL, destinationURL: destinationURL)
    }
    
    private static func compressAndSaveVideo(sourceURL: URL, destinationURL: URL) async -> URL? {
        let asset = AVURLAsset(url: sourceURL)
        
        // Load video track and asset duration
        guard let videoTracks = try? await asset.loadTracks(withMediaType: .video),
              let videoTrack = videoTracks.first,
              let duration = try? await asset.load(.duration) else {
            // Fallback: If loading fails, copy video directly
            return await copyVideoFallback(sourceURL: sourceURL, destinationURL: destinationURL)
        }
        
        // Reduce video to max 720p (sufficient for exercise videos)
        let optimalSize = await calculateOptimalSize(for: videoTrack, maxDimension: 720)
        
        // New API: Use VideoComposition.Configuration
        var videoCompositionConfiguration = AVVideoComposition.Configuration()
        videoCompositionConfiguration.renderSize = optimalSize
        videoCompositionConfiguration.frameDuration = CMTime(value: 1, timescale: 30)
        
        // Simplified compression: Use preset only (Medium Quality already significantly reduces size)
        // Optional: Add VideoComposition for size reduction
        let videoComposition: AVMutableVideoComposition? = nil // Disabled for now, reduces complexity
        
        // Create and use ExportSession
        // Use AVAssetExportPresetHighestQuality to ensure audio is preserved
        // MediumQuality sometimes drops audio, so we'll use HighestQuality but with size reduction
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            return await copyVideoFallback(sourceURL: sourceURL, destinationURL: destinationURL)
        }
        
        exportSession.outputURL = destinationURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        // Verify audio tracks exist and will be preserved
        if let audioTracks = try? await asset.loadTracks(withMediaType: .audio), audioTracks.isEmpty {
            // No audio tracks found, but continue with export
            print("Warning: No audio tracks found in video")
        }
        
        if let videoComposition = videoComposition {
            exportSession.videoComposition = videoComposition
        }
        
        // Execute export async - use old API (still functional)
        return await withCheckedContinuation { (continuation: CheckedContinuation<URL?, Never>) in
            exportSession.exportAsynchronously {
                // Use explicit continuation type to avoid Sendable warning
                let isCompleted: Bool
                isCompleted = exportSession.status == .completed
                
                if isCompleted {
                    // Delete original video (if it was temporary)
                    if sourceURL.path.contains(NSTemporaryDirectory()) {
                        try? FileManager.default.removeItem(at: sourceURL)
                    }
                    continuation.resume(returning: destinationURL)
                } else {
                    let statusRawValue = exportSession.status.rawValue
                    print("Video compression failed: Export status \(statusRawValue)")
                    // Fallback: Copy video directly
                    Task {
                        let result = await copyVideoFallback(sourceURL: sourceURL, destinationURL: destinationURL)
                        continuation.resume(returning: result)
                    }
                }
            }
        }
    }
    
    private static func calculateOptimalSize(for track: AVAssetTrack, maxDimension: CGFloat) async -> CGSize {
        guard let naturalSize = try? await track.load(.naturalSize),
              let preferredTransform = try? await track.load(.preferredTransform) else {
            return CGSize(width: 720, height: 720)
        }
        
        let size = naturalSize.applying(preferredTransform)
        let width = abs(size.width)
        let height = abs(size.height)
        
        if width <= maxDimension && height <= maxDimension {
            return CGSize(width: width, height: height)
        }
        
        let aspectRatio = width / height
        if width > height {
            return CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            return CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
    }
    
    private static func copyVideoFallback(sourceURL: URL, destinationURL: URL) async -> URL? {
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            print("Error copying video: \(error)")
            return nil
        }
    }
    
    static func getVideoURL(fileName: String) -> URL? {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }
    
    // MARK: - Media Cleanup
    
    static func deleteMediaFiles(for exercise: Exercise) {
        for mediaItem in exercise.mediaItems {
            deleteFileFromDocuments(fileName: mediaItem.fileName)
        }
    }
    
    static func deleteMediaFiles(for session: TrainingSession) {
        for exercise in session.exercises {
            deleteMediaFiles(for: exercise)
        }
    }
}
