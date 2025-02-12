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
                            
                            VStack(alignment: .leading, spacing: 2) {
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
                    
                    // Comments
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(comments) { comment in
                            ThreadedCommentView(comment: comment, comments: comments)
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
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let userData = snapshot?.data(),
                  let userName = userData["name"] as? String,
                  let userImageUrl = userData["profileImageUrl"] as? String else { return }
            
            let commentData: [String: Any] = [
                "text": commentText,
                "userId": userId,
                "userName": userName,
                "userImageUrl": userImageUrl,
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
            "imageUrl": "https://example.com/post-image.jpg"
    ]
    
    let mockPost = Post(id: UUID().uuidString, data: mockPostData)
    
    PostInterestDetailView(post: mockPost)
    
}
