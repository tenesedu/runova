import SwiftUI
import FirebaseFirestore
import FirebaseAuth



struct CommentsView: View {
    let post: Post
    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    @State private var comments: [Comment] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Comments List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(comments) { comment in
                            CommentRow(comment: comment)
                        }
                    }
                    .padding()
                }
                
                // Comment Input
                HStack {
                    TextField("Add a comment...", text: $commentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(isLoading)
                    
                    Button(action: submitComment) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(commentText.isEmpty ? .gray : .blue)
                    }
                    .disabled(commentText.isEmpty || isLoading)
                }
                .padding()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                fetchComments()
            }
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
    
    private func submitComment() {
        guard let userId = Auth.auth().currentUser?.uid,
              !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isLoading = true
        let db = Firestore.firestore()
        
        // First get user data
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let userData = snapshot?.data() else {
                isLoading = false
                return
            }
            
            let comment: [String: Any] = [
                "userId": userId,
                "userName": userData["name"] as? String ?? "",
                "userProfileUrl": userData["profileImageUrl"] as? String ?? "",
                "content": commentText,
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            // Add comment and update post's comment count
            let batch = db.batch()
            
            // Add comment
            let commentRef = db.collection("posts").document(post.id)
                .collection("comments").document()
            batch.setData(comment, forDocument: commentRef)
            
            // Update post's comment count
            let postRef = db.collection("posts").document(post.id)
            batch.updateData(["comments": FieldValue.increment(Int64(1))], forDocument: postRef)
            
            batch.commit { error in
                isLoading = false
                if error == nil {
                    commentText = ""
                }
            }
        }
    }
}


    
