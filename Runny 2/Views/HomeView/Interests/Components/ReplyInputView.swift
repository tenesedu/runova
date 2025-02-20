import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ReplyInputView: View {
    let comment: Comment
    @Binding var isReplying: Bool
    @State private var replyText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                TextField("Write a reply...", text: $replyText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 14))
                    .focused($isFocused)
                
                if !replyText.isEmpty {
                    Button(action: postReply) {
                        Text("Reply")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
                
                Button(action: { isReplying = false }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            isFocused = true
        }
    }
    
    private func postReply() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let userData = snapshot?.data(),
                  let userName = userData["name"] as? String,
                  let userImageUrl = userData["profileImageUrl"] as? String else { return }
            
            let replyData: [String: Any] = [
                "text": replyText,
                "userId": userId,
                "userName": userName,
                "userImageUrl": userImageUrl,
                "createdAt": FieldValue.serverTimestamp(),
                "parentId": comment.id,
                "postId": comment.postId,
                "likesCount": 0
            ]
            
            // Add reply to comments collection
            db.collection("posts").document(comment.postId)
                .collection("comments")
                .addDocument(data: replyData) { error in
                    if error == nil {
                        replyText = ""
                        isReplying = false
                    }
                }
        }
    }
} 