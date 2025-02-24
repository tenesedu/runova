import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PostInterestDetailView: View {
    let post: Post
    
    @State private var comments: [Comment] = []
    @State private var commentText = ""
    @State private var isLiked = false
    @State private var likesCount: Int
    @FocusState private var isCommentFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(post: Post) {
        self.post = post
        _likesCount = State(initialValue: post.likesCount)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Post Content
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: post.creatorImageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                            
                            HStack(spacing: 16) {
                                Text(post.creatorName)
                                    .font(.system(size: 16, weight: .semibold))
                                Text(post.createdAt.timeAgo())
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        
                        Text(post.content)
                            .font(.system(size: 16))
                        
                        // Post Images
                        if !post.imagesUrls.isEmpty {
                            if post.imagesUrls.count == 1 {
                                // Safely unwrap the first image URL
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
                                // Multiple images scroll
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
                                                        .cornerRadius(8)
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
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        HStack(spacing: 24) {
                            Button(action: toggleLike) {
                                HStack(spacing: 4) {
                                    Image(systemName: isLiked ? "heart.fill" : "heart")
                                        .foregroundColor(isLiked ? .red : .gray)
                                    Text("\(likesCount)")
                                }
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left")
                                Text("\(comments.count)")
                            }
                            
                            Spacer()
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    }
                    .padding()
                    
                    Divider()
                    HStack(spacing: 0) {
                        Text("Responses")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    Divider()
                    
                    // Comments
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(comments) { comment in
                            CommentRow(comment: comment)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
            
            // Comment Input
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: UserDefaults.standard.string(forKey: "userProfileImage") ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    
                    TextField("Add a comment...", text: $commentText)
                        .textFieldStyle(.roundedBorder)
                        .focused($isCommentFocused)
                    
                    if !commentText.isEmpty {
                        Button(action: postComment) {
                            Text("Post")
                                .foregroundColor(.blue)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Thread")
        .onAppear {
            fetchComments()
            checkIfLiked()
        }
    }
    
    private func fetchComments() {
        let db = Firestore.firestore()
        db.collection("posts").document(post.id)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                comments = documents.map { Comment(id: $0.documentID, data: $0.data(), postId: post.id) }
            }
    }

    private func toggleLike() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let likeRef = db.collection("posts").document(post.id)
            .collection("likes").document(userId)
        
        if isLiked {
            // Unlike
            likeRef.delete()
            updateLikesCount(increment: false)
        } else {
            // Like
            likeRef.setData([:])
            updateLikesCount(increment: true)
        }
        
        isLiked.toggle()
    }
    
    private func updateLikesCount(increment: Bool) {
        let db = Firestore.firestore()
        db.collection("posts").document(post.id).updateData([
            "likesCount": FieldValue.increment(increment ? Int64(1) : Int64(-1))
        ])
        likesCount += increment ? 1 : -1
    }
    
    private func postComment() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
            
            let commentData: [String: Any] = [
                "text": commentText,
                "userId": userId,
                "createdAt": FieldValue.serverTimestamp(),
                "likesCount": 0
            ]
            
            db.collection("posts").document(post.id)
                .collection("comments").addDocument(data: commentData) { error in
                    if error == nil {
                        db.collection("posts").document(post.id)
                            .updateData(["commentsCount": FieldValue.increment(Int64(1))])
                        commentText = ""
                        isCommentFocused = false
                    }
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
} 

#Preview {
    let mockPostData: [String: Any] = [
        "content": "This is a mock post about technology and innovation.",
            "interestId": "tech123",
            "interestName": "Technology",
            "createdAt": Date(),
            "createdBy": "user123",
            "creatorName": "John Doe",
            "creatorImageUrl": "https://example.com/profile.jpg",
            "likesCount": 25,
            "commentsCount": 10,
            "imageUrl": "https://static.wikia.nocookie.net/zelda/images/e/e1/Link_Artwork_2_%28The_Minish_Cap%29.png/revision/latest?cb=20120124213342&path-prefix=es"
    ]
    
    let mockPost = Post(id: UUID().uuidString, data: mockPostData)
    
    PostInterestDetailView(post: mockPost)
    
}
