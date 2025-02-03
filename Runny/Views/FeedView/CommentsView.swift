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
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching comments: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                comments = documents.map { Comment(id: $0.documentID, data: $0.data()) }
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

struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User Profile Image
            AsyncImage(url: URL(string: comment.userProfileUrl ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                // User Name and Timestamp
                HStack {
                    Text(comment.userName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(timeAgo(from: comment.timestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Comment Content
                Text(comment.content)
                    .font(.subheadline)
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
} 
