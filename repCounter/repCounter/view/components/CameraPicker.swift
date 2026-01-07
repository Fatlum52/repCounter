import SwiftUI
#if os(iOS)
import UIKit
import AVFoundation

enum CameraMode {
    case photo
    case video
}

/// SwiftUI-Wrapper um UIImagePickerController (Kamera)
struct CameraPicker: UIViewControllerRepresentable {

    let mode: CameraMode
    
    /// Wird aufgerufen, wenn ein Foto gemacht wurde.
    let onImage: ((UIImage) -> Void)?
    
    /// Wird aufgerufen, wenn ein Video aufgenommen wurde.
    let onVideo: ((URL) -> Void)?

    /// Optional: wird aufgerufen, wenn abgebrochen wurde.
    var onCancel: () -> Void = {}

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()

        // Kamera prüfen (Simulator hat z.B. keine Kamera)
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return picker
        }

        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .fullScreen
        
        switch mode {
        case .photo:
            picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera)?.filter { $0 == "public.image" } ?? ["public.image"]
        case .video:
            picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera)?.filter { $0 == "public.movie" } ?? ["public.movie"]
            picker.videoQuality = .typeHigh
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage, onVideo: onVideo, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

        private let onImage: ((UIImage) -> Void)?
        private let onVideo: ((URL) -> Void)?
        private let onCancel: () -> Void

        init(onImage: ((UIImage) -> Void)?,
             onVideo: ((URL) -> Void)?,
             onCancel: @escaping () -> Void) {
            self.onImage = onImage
            self.onVideo = onVideo
            self.onCancel = onCancel
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

            // Handle Image
            if let image = info[.originalImage] as? UIImage {
                onImage?(image)
            }
            
            // Handle Video
            if let videoURL = info[.mediaURL] as? URL {
                onVideo?(videoURL)
            }

            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
            picker.dismiss(animated: true)
        }
    }
}
#endif

