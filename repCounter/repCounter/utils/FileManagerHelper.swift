import Foundation
import SwiftUI
#if os(iOS)
import UIKit
import AVFoundation
#elseif os(macOS)
import AppKit
import AVFoundation
#endif

// helper class for photo, video handling
class FileManagerHelper {

    // MARK: - Documents Directory

    // documents directory of the app
    static func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Image Support

#if os(iOS)

    // saves UIImage as jpge in document directory
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

    // loads saved image as SwiftUI Image
    static func loadImageFromDocuments(fileName: String) -> Image? {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        guard let uiImage = UIImage(contentsOfFile: url.path) else { return nil }
        return Image(uiImage: uiImage)
    }

#elseif os(macOS)

    // saves NSImage as jpeg in documents directory
    static func saveImageToDocuments(image: NSImage, fileName: String) -> URL? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let data = bitmapImage.representation(
                using: .jpeg,
                properties: [.compressionFactor: 0.8]
              ) else { return nil }

        let url = getDocumentsDirectory().appendingPathComponent(fileName)

        do {
            try data.write(to: url)
            return url
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }

    // loads saved photo as SwiftUI Image
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

        exportSession.outputURL = destinationURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        // asynchronous export
        return await withCheckedContinuation { continuation in
            exportSession.exportAsynchronously {

                if exportSession.status == .completed {

                    // temporary camera-video after export delete
                    if sourceURL.path.contains(NSTemporaryDirectory()) {
                        try? FileManager.default.removeItem(at: sourceURL)
                    }

                    continuation.resume(returning: destinationURL)

                } else {
                    print("Video export failed: \(exportSession.status.rawValue)")

                    Task {
                        let fallback = await copyVideoFallback(
                            sourceURL: sourceURL,
                            destinationURL: destinationURL
                        )
                        continuation.resume(returning: fallback)
                    }
                }
            }
        }
    }

    // calculates scaled video-size with ration aspect
    private static func calculateOptimalSize(
        for track: AVAssetTrack,
        maxDimension: CGFloat
    ) async -> CGSize {

        guard let naturalSize = try? await track.load(.naturalSize),
              let transform = try? await track.load(.preferredTransform) else {
            return CGSize(width: maxDimension, height: maxDimension)
        }

        let size = naturalSize.applying(transform)
        let width = abs(size.width)
        let height = abs(size.height)

        if width <= maxDimension && height <= maxDimension {
            return CGSize(width: width, height: height)
        }

        let aspectRatio = width / height

        if width > height {
            return CGSize(
                width: maxDimension,
                height: maxDimension / aspectRatio
            )
        } else {
            return CGSize(
                width: maxDimension * aspectRatio,
                height: maxDimension
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
            print("Error copying video: \(error)")
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
    static func deleteMediaFiles(for session: TrainingSession) {
        for exercise in session.exercises {
            deleteMediaFiles(for: exercise)
        }
    }
}
