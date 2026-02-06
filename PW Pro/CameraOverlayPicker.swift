import SwiftUI
import UIKit

/// Wraps UIImagePickerController to present camera with a translucent overlay image (the 'ghost')
struct CameraOverlayPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    let overlayImage: UIImage?
    let completion: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator

        if let overlay = overlayImage {
            let overlayView = UIImageView(image: overlay)
            overlayView.contentMode = .scaleAspectFit
            overlayView.alpha = 0.35
            overlayView.frame = UIScreen.main.bounds
            overlayView.backgroundColor = UIColor.clear
            picker.cameraOverlayView = overlayView
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraOverlayPicker
        init(_ parent: CameraOverlayPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            var image: UIImage? = nil
            if let img = info[.originalImage] as? UIImage {
                image = img
            }
            parent.completion(image)
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(nil)
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
