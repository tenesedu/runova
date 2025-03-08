import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct NewInterestPostView: View {
    @Environment(\.dismiss) private var dismiss
    let interest: Interest
    
    @State private var content: String = ""
    @State private var selectedImages: [UIImage] = []
    @State private var selectedPhotoImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @FocusState private var isFocused: Bool
    @State private var userImage: String = ""
    @State private var userName: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Text(NSLocalizedString("Cancel", comment: ""))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text(NSLocalizedString("New Thread", comment: ""))
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: createPost) {
                        Text(NSLocalizedString("Post", comment: ""))
                            .fontWeight(.semibold)
                            
                            .foregroundColor(!content.isEmpty || !selectedImages.isEmpty ? .blue : .gray)
                    }
                    
                    .disabled(content.isEmpty && selectedImages.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
            }

            // User Info Section
             HStack(alignment: .top, spacing: 12) {
                // User Profile Image
                AsyncImage(url: URL(string: userImage)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    // User Name
                    Text(userName)
                        .font(.system(size: 15, weight: .semibold))
                    
                    // Text Input
                    TextField(LocalizedStringKey("Start a thread..."), text: $content, axis: .vertical)
                        .focused($isFocused)
                        .textInputAutocapitalization(.never)
                        .frame(minHeight: 50)
                        // Selected Image (if any)
                        }
             }
             .padding(16)
            
            // Content Area
            ScrollView {
                VStack(spacing: 0) {
                        
                    if !selectedImages.isEmpty {
                        if selectedImages.count == 1 {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImages[0])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity, maxHeight: 300) // Adjust size as needed
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .padding(.horizontal)
                                
                                Button(action: {
                                    selectedImages.remove(at: 0)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .padding(8)
                            }
                        }else {
                            // Display multiple images in a horizontal ScrollView
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(selectedImages, id: \.self) { image in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 200) // Adjust size as needed
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
                                            Button(action: {
                                                if let index = selectedImages.firstIndex(of: image) {
                                                    selectedImages.remove(at: index)
                                                }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.white)
                                                    .background(Circle().fill(Color.black.opacity(0.5)))
                                            }
                                            .padding(8)
                                        }
                                    }
                                }
                                //.padding(.horizontal)
                            }
                            //.padding(.top, 12)
                        }
                    
                      
                    }
                    // Media Icons
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        Button(action: { showingImagePicker = true }) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                        
                        Button(action: {  showingCamera = true }) {
                            Image(systemName: "camera")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.top, 16)
                } 
                .padding(.horizontal, 24)
            }
        
     
            
            // Bottom Toolbar with Post Button
            if isFocused {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    HStack {
                        Text("Anyone can reply")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Button(action: createPost) {
                            Text("Post")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(content.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
                                .cornerRadius(20)
                        }
                        .disabled(content.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagesPicker(selectedImages: $selectedImages)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(isPresented: $showingCamera, image: $selectedPhotoImage)
                .onDisappear {
                    if let image = selectedPhotoImage {
                        selectedImages.append(image)
                    }
                }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            fetchUserData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
    
    private func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let userData = snapshot?.data() {
                self.userImage = userData["profileImageUrl"] as? String ?? ""
                self.userName = userData["name"] as? String ?? ""
            }
        }
    }
    
    private func createPost() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        let db = Firestore.firestore()
        
        // First check if user is following the interest
        db.collection("interests")
            .document(interest.id)
            .collection("followers")
            .document(userId)
            .getDocument { snapshot, error in
                guard let exists = snapshot?.exists, exists else {
                    isLoading = false
                    alertMessage = "You must follow this interest to create posts"
                    showAlert = true
                    return
                }
                
                // Get user data and create post
                db.collection("users").document(userId).getDocument { snapshot, error in
                    guard let userData = snapshot?.data(),
                          let userName = userData["name"] as? String,
                          let userImageUrl = userData["profileImageUrl"] as? String else {
                        isLoading = false
                        alertMessage = "Error fetching user data"
                        showAlert = true
                        return
                    }
                    
                    if !selectedImages.isEmpty {
                        uploadImages(selectedImages) { imagesUrls in
                            guard !imagesUrls.isEmpty else {
                                isLoading = false
                                alertMessage = "Error uploading image"
                                showAlert = true
                                return
                            }
                            
                            let postData: [String: Any] = [
                                "content": content,
                                "interestId": interest.id,
                                "interestName": interest.name,
                                "createdAt": FieldValue.serverTimestamp(),
                                "createdBy": userId,
                                "creatorName": userName,
                                "creatorImageUrl": userImageUrl,
                                "likesCount": 0,
                                "commentsCount": 0,
                                "imagesUrls": imagesUrls
                            ]
                            
                            createPostInFirestore(postData)
                        }
                    } else {
                        let postData: [String: Any] = [
                            "content": content,
                            "interestId": interest.id,
                            "interestName": interest.name,
                            "createdAt": FieldValue.serverTimestamp(),
                            "createdBy": userId,
                            "creatorName": userName,
                            "creatorImageUrl": userImageUrl,
                            "likesCount": 0,
                            "commentsCount": 0
                        ]
                        
                        createPostInFirestore(postData)
                    }
                }
            }
    }
    
    private func createPostInFirestore(_ postData: [String: Any]) {
        let db = Firestore.firestore()
        db.collection("posts").addDocument(data: postData) { error in
            isLoading = false
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else {
                dismiss()
            }
        }
    }
    
    private func uploadImages(_ images: [UIImage], completion: @escaping ([String]) -> Void) {
        let storage = Storage.storage()
        let dispatchGroup = DispatchGroup()
        var imageUrls: [String] = []
        
        for image in images {
            dispatchGroup.enter()
            guard let imageData = image.jpegData(compressionQuality: 0.5) else {
                dispatchGroup.leave()
                continue
            }
            
            let storageRef = storage.reference()
            let imageRef = storageRef.child("post_images/\(UUID().uuidString).jpg")
            
            imageRef.putData(imageData, metadata: nil) { metadata, error in
                if error != nil {
                    dispatchGroup.leave()
                    return
                }
                
                imageRef.downloadURL { url, error in
                    if let url = url {
                        imageUrls.append(url.absoluteString)
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(imageUrls)
        }
    }
}

#Preview {
    // Mock Interest Data
    let mockInterestData: [String: Any] = [
        "name": "Technology",
        "iconName": "laptopcomputer",
        "backgroundImageUrl": "https://example.com/tech-background.jpg",
        "description": "Explore the latest in tech and innovation.",
        "color": "#007AFF", // Hex color for blue
        "followerCount": 1200,
        "createdBy": "user123",
        "createdAt": Timestamp(date: Date())
    ]
    
    let mockInterest = Interest(id: "1", data: mockInterestData)
    
    NewInterestPostView(interest: mockInterest)
    
}

