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
        
        // Wenn Datei bereits existiert, löschen
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        
        // Video komprimieren und speichern
        return await compressAndSaveVideo(sourceURL: videoURL, destinationURL: destinationURL)
    }
    
    private static func compressAndSaveVideo(sourceURL: URL, destinationURL: URL) async -> URL? {
        let asset = AVURLAsset(url: sourceURL)
        
        // Lade Video-Track und Asset-Dauer
        guard let videoTracks = try? await asset.loadTracks(withMediaType: .video),
              let videoTrack = videoTracks.first,
              let duration = try? await asset.load(.duration) else {
            // Fallback: Falls Laden fehlschlägt, Video direkt kopieren
            return await copyVideoFallback(sourceURL: sourceURL, destinationURL: destinationURL)
        }
        
        // Video auf max. 720p reduzieren (für Übungsvideos ausreichend)
        let optimalSize = await calculateOptimalSize(for: videoTrack, maxDimension: 720)
        
        // Neue API: VideoComposition.Configuration verwenden
        var videoCompositionConfiguration = AVVideoComposition.Configuration()
        videoCompositionConfiguration.renderSize = optimalSize
        videoCompositionConfiguration.frameDuration = CMTime(value: 1, timescale: 30)
        
        // Vereinfachte Kompression: Nur Preset verwenden (Medium Quality reduziert bereits Größe erheblich)
        // Optional: VideoComposition für Größenreduzierung hinzufügen
        let videoComposition: AVMutableVideoComposition? = nil // Für jetzt deaktiviert, reduziert Komplexität
        
        // ExportSession erstellen und verwenden
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            return await copyVideoFallback(sourceURL: sourceURL, destinationURL: destinationURL)
        }
        
        exportSession.outputURL = destinationURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        if let videoComposition = videoComposition {
            exportSession.videoComposition = videoComposition
        }
        
        // Export async ausführen - verwende die alte API (noch funktional)
        return await withCheckedContinuation { (continuation: CheckedContinuation<URL?, Never>) in
            exportSession.exportAsynchronously {
                // Verwende @preconcurrency um Sendable-Warnung zu vermeiden
                let isCompleted: Bool
                isCompleted = exportSession.status == .completed
                
                if isCompleted {
                    // Original-Video löschen (falls es temporär war)
                    if sourceURL.path.contains(NSTemporaryDirectory()) {
                        try? FileManager.default.removeItem(at: sourceURL)
                    }
                    continuation.resume(returning: destinationURL)
                } else {
                    let statusRawValue = exportSession.status.rawValue
                    print("Video compression failed: Export status \(statusRawValue)")
                    // Fallback: Video direkt kopieren
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
}
