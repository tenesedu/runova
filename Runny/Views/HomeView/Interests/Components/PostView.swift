import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PostView: View {
    let post: Post
    @State private var isLiked = false
    @State private var showingDetail = false
    @State private var showingCommentSheet = false
    @State private var newComment = ""
    @FocusState private var isCommentFocused: Bool
    @State private var showingImageModal = false
    @State private var selectedImage: String?
    let onPostTap: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Info Header
            HStack(spacing: 10) {
                AsyncImage(url: URL(string: post.creatorImageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.creatorName)
                        .font(.system(size: 15, weight: .semibold))
                    
                    Text(post.createdAt.timeAgo())
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Post Content
            Text(post.content)
                .font(.system(size: 15))
                .multilineTextAlignment(.leading)
            
            // Post Images
            if !post.imagesUrls.isEmpty {
                if post.imagesUrls.count == 1 {
                    if let firstImageUrl = post.imagesUrls[0] {
                        AsyncImage(url: URL(string: firstImageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, idealHeight: 300)
                                    .background(Color.gray.opacity(0.3))
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        selectedImage = firstImageUrl
                                        showingImageModal = true
                                    }
                            case .failure:
                                Image(systemName: "xmark.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.red)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 400)
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(post.imagesUrls.compactMap { $0 }, id: \.self) { url in
                                AsyncImage(url: URL(string: url)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 200, height: 200)
                                            .background(Color.gray.opacity(0.3))
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 200, height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .onTapGesture {
                                                selectedImage = url
                                                showingImageModal = true
                                            }
                                    case .failure:
                                        Image(systemName: "xmark.circle")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(.red)
                                            .frame(width: 200, height: 200)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Action Buttons
            HStack(spacing: 24) {
                Button(action: toggleLike) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                        Text("\(post.likesCount)")
                    }
                }
                
                Button(action: {
                    showingCommentSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                        Text("\(post.commentsCount)")
                    }
                    .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .font(.system(size: 14))
            .foregroundColor(.gray)
        }
        .contentShape(Rectangle())
        .padding(.horizontal)
        .padding(.vertical, 12)
        .onAppear {
            checkIfLiked()
        }
        .sheet(isPresented: $showingImageModal) {
            if let imageUrl = selectedImage {
                ImageModalView(imageUrl: imageUrl)
            }
        }
    }
    
    private func toggleLike() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let likeRef = db.collection("posts").document(post.id)
        
        if isLiked {
            likeRef.collection("likes").document(userId).delete()
            likeRef.updateData(["likesCount": FieldValue.increment(Int64(-1))])
            
        } else {
            
            let likeData: [String: Any] = [
                "userId": userId,
                "likedAt": FieldValue.serverTimestamp()
            ]
            
            likeRef.collection("likes").document(userId).setData(likeData)
            likeRef.updateData(["likesCount": FieldValue.increment(Int64(1))])
            
        }
    }
    
    private func checkIfLiked() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("posts").document(post.id)
            .collection("likes").document(userId)
            .addSnapshotListener { snapshot, error in
                isLiked = snapshot?.exists ?? false
            }
    }
    
    private func postComment() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let userData = snapshot?.data(),
                  let userName = userData["name"] as? String,
                  let userImageUrl = userData["profileImageUrl"] as? String else { return }
            
            let commentData: [String: Any] = [
                "text": newComment,
                "userId": userId,
                "userName": userName,
                "userImageUrl": userImageUrl,
                "createdAt": FieldValue.serverTimestamp(),
                "likesCount": 0
            ]
            
            db.collection("posts").document(post.id)
                .collection("comments").addDocument(data: commentData) { error in
                    if error == nil {
                        // Update post comments count
                        db.collection("posts").document(post.id)
                            .updateData(["commentsCount": FieldValue.increment(Int64(1))])
                        newComment = ""
                        showingCommentSheet = false
                    }
                }
        }
    }
}

struct ImageModalView: View {
    let imageUrl: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    case .failure:
                        Image(systemName: "xmark.circle")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.red)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    
    
    let mockPostData: [String: Any] = [
        "content": "This is a mock post about technology and innovation.",
            "interestId": "tech123",
            "interestName": "Technology",
            "createdAt": Date(),
            "createdBy": "user123",
            "creatorName": "John Doe",
            "creatorImageUrl": "star.fill",
            "likesCount": 25,
            "commentsCount": 10,
            "imageUrl": "https://static.wikia.nocookie.net/zelda/images/e/e1/Link_Artwork_2_%28The_Minish_Cap%29.png/revision/latest?cb=20120124213342&path-prefix=es"
    ]
    
    let mockPost = Post(id: UUID().uuidString, data: mockPostData)
    
    PostView(post: mockPost, onPostTap: nil)
    
}

