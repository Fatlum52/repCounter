import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
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
    
    static func saveVideoToDocuments(videoURL: URL, fileName: String) -> URL? {
        let destinationURL = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            // Wenn Datei bereits existiert, löschen
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            // Video kopieren
            try FileManager.default.copyItem(at: videoURL, to: destinationURL)
            return destinationURL
        } catch {
            print("Error saving video: \(error)")
            return nil
        }
    }
    
    static func getVideoURL(fileName: String) -> URL? {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }
}
