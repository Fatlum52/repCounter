import Foundation
import SwiftUI

enum CameraMode {
    case photo
    case video
}

#if os(iOS)
import UIKit

struct CameraView: UIViewControllerRepresentable {
    
    @Binding var image: UIImage? // bind to the parent views state
    @Binding var videoURL: URL? // bind to the parent views state for video
    var mode: CameraMode // photo or video mode
    var onImageCaptured: ((UIImage) -> Void)? // callback for captured image
    var onVideoCaptured: ((URL) -> Void)? // callback for captured video
    @Environment(\.presentationMode) var presentationMode // dismiss the view when done
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController() // create camera picker
        
        // Check if camera is available
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return picker
        }
        
        picker.delegate = context.coordinator // set coordinator as delegate
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.modalPresentationStyle = .fullScreen
        
        // Configure media types based on mode
        switch mode {
        case .photo:
            picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera)?.filter { $0 == "public.image" } ?? ["public.image"]
        case .video:
            picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera)?.filter { $0 == "public.movie" } ?? ["public.movie"]
            picker.videoQuality = .typeHigh
        }
        
        return picker
    }
    
    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {
        // no updates needed here
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            // Handle image
            if let image = info[.originalImage] as? UIImage {
                DispatchQueue.main.async {
                    self.parent.image = image
                    self.parent.onImageCaptured?(image)
                }
            }
            
            // Handle video
            if let videoURL = info[.mediaURL] as? URL {
                DispatchQueue.main.async {
                    self.parent.videoURL = videoURL
                    self.parent.onVideoCaptured?(videoURL)
                }
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss() // dismiss on cancel
        }
    }
}
#endif
