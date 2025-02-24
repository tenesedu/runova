//
//  ImagesPicker.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 24/2/25.
//

import SwiftUI
import PhotosUI // Import PhotosUI for PHPickerViewController

struct ImagesPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage] // Array to hold multiple images
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images // Only allow images
        config.selectionLimit = 10 // Allow up to 10 images (set to 0 for unlimited)
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagesPicker
        
        init(_ parent: ImagesPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Clear existing images
            //parent.selectedImages.removeAll()
            
            // Load each selected image
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedImages.append(image)
                        }
                    }
                }
            }
            
            // Dismiss the picker
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
/*
#Preview {
    ImagesPicker()
}
*/
