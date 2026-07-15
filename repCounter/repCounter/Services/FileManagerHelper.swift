import Foundation
import SwiftUI
import os
#if os(iOS)
import UIKit
import AVFoundation
#elseif os(macOS)
import AppKit
import AVFoundation
#endif

// Namespace for photo/video file handling.
enum FileManagerHelper {

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "repCounter", category: "FileManager")

    // MARK: - Documents Directory
    // documents directory of the app
    static func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Image Support
#if os(iOS)
    // saves UIImage as jpeg in documents directory (background QoS to avoid priority inversion)
    @discardableResult
    static func saveImageToDocuments(image: UIImage, fileName: String) async -> URL? {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                guard let data = image.jpegData(compressionQuality: 0.8) else {
                    continuation.resume(returning: nil)
                    return
                }
                do {
                    try data.write(to: url)
                    continuation.resume(returning: url)
                } catch {
                    logger.error("Error saving image: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // loads saved image as SwiftUI Image
    static func loadImageFromDocuments(fileName: String) -> Image? {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        guard let uiImage = UIImage(contentsOfFile: url.path) else { return nil }
        return Image(uiImage: uiImage)
    }

#elseif os(macOS)

    // saves NSImage as jpeg in documents directory (background QoS to avoid priority inversion)
    @discardableResult
    static func saveImageToDocuments(image: NSImage, fileName: String) async -> URL? {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                guard let tiffData = image.tiffRepresentation,
                      let bitmapImage = NSBitmapImageRep(data: tiffData),
                      let data = bitmapImage.representation(
                        using: .jpeg,
                        properties: [.compressionFactor: 0.8]
                      ) else {
                    continuation.resume(returning: nil)
                    return
                }
                do {
                    try data.write(to: url)
                    continuation.resume(returning: url)
                } catch {
                    logger.error("Error saving image: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // loads saved image as SwiftUI Image
    static func loadImageFromDocuments(fileName: String) -> Image? {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        guard let nsImage = NSImage(contentsOfFile: url.path) else { return nil }
        return Image(nsImage: nsImage)
    }

#endif

    // deletes file from documents directory
    static func deleteFileFromDocuments(fileName: String) {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Video Support
    // public entrypoint to safe videos
    static func saveVideoToDocuments(videoURL: URL, fileName: String) async -> URL? {
        let destinationURL = getDocumentsDirectory().appendingPathComponent(fileName)

        // no duplicates, removes existing file
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }

        return await compressAndSaveVideo(
            sourceURL: videoURL,
            destinationURL: destinationURL
        )
    }

    // compromises video depending the source (camera or upload
    private static func compressAndSaveVideo(
        sourceURL: URL,
        destinationURL: URL
    ) async -> URL? {

        let asset = AVURLAsset(url: sourceURL)

        // uploaded videos normally are not from temp-directory
        let isUploadedVideo = !sourceURL.path.contains(NSTemporaryDirectory())

        // preset depending on source
        // uploads compromise more aggressiv
        let preset: String = isUploadedVideo
            ? AVAssetExportPreset640x480
            : AVAssetExportPresetMediumQuality

        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: preset
        ) else {
            return await copyVideoFallback(
                sourceURL: sourceURL,
                destinationURL: destinationURL
            )
        }

        exportSession.shouldOptimizeForNetworkUse = true

        // export using iOS 18+ API
        do {
            try await exportSession.export(to: destinationURL, as: .mp4)

            // clean up temporary camera video after export
            if sourceURL.path.contains(NSTemporaryDirectory()) {
                try? FileManager.default.removeItem(at: sourceURL)
            }

            return destinationURL
        } catch {
            logger.error("Video export failed: \(error.localizedDescription)")
            return await copyVideoFallback(
                sourceURL: sourceURL,
                destinationURL: destinationURL
            )
        }
    }

    // fallback: copy video without changes if export-errors
    private static func copyVideoFallback(
        sourceURL: URL,
        destinationURL: URL
    ) async -> URL? {
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            logger.error("Error copying video: \(error.localizedDescription)")
            return nil
        }
    }

    // returns URL of saved video if there
    static func getVideoURL(fileName: String) -> URL? {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Media Cleanup
    // deletes media from exercise
    static func deleteMediaFiles(for exercise: Exercise) {
        for mediaItem in exercise.mediaItems {
            deleteFileFromDocuments(fileName: mediaItem.fileName)
        }
    }

    // deletes media from training session
    static func deleteMediaFiles(for session: Session) {
        for exercise in session.exerciseList {
            deleteMediaFiles(for: exercise)
        }
    }
}
