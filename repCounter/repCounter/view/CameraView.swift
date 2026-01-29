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
        print("📷 [CameraView] makeUIViewController called - mode: \(mode)")
        let picker = UIImagePickerController() // create camera picker
        
        // Check if camera is available
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("❌ [CameraView] Camera not available!")
            return picker
        }
        
        picker.delegate = context.coordinator // set coordinator as delegate
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.modalPresentationStyle = .fullScreen
        
        // Configure media types based on mode
        switch mode {
        case .photo:
            let mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera)?.filter { $0 == "public.image" } ?? ["public.image"]
            picker.mediaTypes = mediaTypes
            print("📷 [CameraView] Configured for photo mode - mediaTypes: \(mediaTypes)")
        case .video:
            let mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera)?.filter { $0 == "public.movie" } ?? ["public.movie"]
            picker.mediaTypes = mediaTypes
            picker.videoQuality = .typeHigh
            print("📹 [CameraView] Configured for video mode - mediaTypes: \(mediaTypes)")
        }
        
        print("✅ [CameraView] UIImagePickerController created and configured")
        return picker
    }
    
    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {
        print("🔄 [CameraView] updateUIViewController called - mode: \(mode)")
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
            print("📷 [CameraView] didFinishPickingMediaWithInfo called")
            
            // Handle image
            if let image = info[.originalImage] as? UIImage {
                print("📷 [CameraView] Image captured - size: \(image.size)")
                DispatchQueue.main.async {
                    print("📷 [CameraView] Setting image on main thread")
                    self.parent.image = image
                    self.parent.onImageCaptured?(image)
                    print("📷 [CameraView] onImageCaptured callback executed")
                }
            }
            
            // Handle video
            if let videoURL = info[.mediaURL] as? URL {
                print("📹 [CameraView] Video captured - URL: \(videoURL)")
                DispatchQueue.main.async {
                    print("📹 [CameraView] Setting videoURL on main thread")
                    self.parent.videoURL = videoURL
                    self.parent.onVideoCaptured?(videoURL)
                    print("📹 [CameraView] onVideoCaptured callback executed")
                }
            }
            
            print("📷 [CameraView] Dismissing camera view")
            parent.presentationMode.wrappedValue.dismiss()
            print("📷 [CameraView] Dismiss called")
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("❌ [CameraView] imagePickerControllerDidCancel called")
            parent.presentationMode.wrappedValue.dismiss() // dismiss on cancel
            print("📷 [CameraView] Dismiss called (cancel)")
        }
    }
}
#endif
