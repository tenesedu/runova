import SwiftUI
import UIKit
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.image = selectedImage
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        // Verificar permisos de cámara antes de intentar usarla
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupPickerController(picker, context: context)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        setupPickerController(picker, context: context)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isPresented = false
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.isPresented = false
                // Aquí podrías mostrar una alerta para dirigir al usuario a Configuración
            }
        @unknown default:
            break
        }
        
        return picker
    }
    
    private func setupPickerController(_ picker: UIImagePickerController, context: Context) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        picker.allowsEditing = false
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
