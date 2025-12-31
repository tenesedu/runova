//
//  ProfileImageStep.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 20/2/25.
//

import SwiftUI

struct ProfileImageStep: View {
    @Binding var image: UIImage?
    @Binding var showImagePicker: Bool
    
    var body: some View {
        VStack {
            Button(action: { showImagePicker = true }) {
                Text("Select Profile Image")
            }
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            }
               
        }
        .fullScreenCover(isPresented: $showImagePicker) {
            ImagePicker(image: $image)
        }
    }
}
