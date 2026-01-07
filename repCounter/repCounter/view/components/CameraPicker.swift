import SwiftUI
#if os(iOS)
import UIKit

/// SwiftUI-Wrapper um UIImagePickerController (Kamera)
struct CameraPicker: UIViewControllerRepresentable {

    /// Wird aufgerufen, wenn ein Foto gemacht wurde.
    let onImage: (UIImage) -> Void

    /// Optional: wird aufgerufen, wenn abgebrochen wurde.
    var onCancel: () -> Void = {}

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()

        // Kamera prüfen (Simulator hat z.B. keine Kamera)
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return picker
        }

        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

        private let onImage: (UIImage) -> Void
        private let onCancel: () -> Void

        init(onImage: @escaping (UIImage) -> Void,
             onCancel: @escaping () -> Void) {
            self.onImage = onImage
            self.onCancel = onCancel
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

            if let image = info[.originalImage] as? UIImage {
                onImage(image)
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

