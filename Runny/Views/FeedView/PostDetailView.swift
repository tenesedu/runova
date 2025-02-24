// import SwiftUI
// import FirebaseFirestore
// import FirebaseAuth

// struct PostDetailView: View {
//     let post: Post
//     @Environment(\.dismiss) private var dismiss
//     @State private var isLiked: Bool = false
//     @State private var showingComments = false
//     @State private var likesCount: Int
    
//     init(post: Post) {
//         self.post = post
//         self._likesCount = State(initialValue: post.likesCount)
//     }
    
//     var body: some View {
//         ScrollView {
//             VStack(alignment: .leading, spacing: 16) {
//                 // User Info
//                 HStack {
//                     AsyncImage(url: URL(string: post.creatorImageUrl ?? "")) { image in
//                         image
//                             .resizable()
//                             .scaledToFill()
//                     } placeholder: {
//                         Image(systemName: "person.circle.fill")
//                             .foregroundColor(.gray)
//                     }
//                     .frame(width: 50, height: 50)
//                     .clipShape(Circle())
                    
//                     VStack(alignment: .leading) {
//                         Text(post.creatorName)
//                             .font(.headline)
//                         Text(post.interestName)
//                             .font(.subheadline)
//                             .foregroundColor(.blue)
//                     }
                    
//                     Spacer()
                    
//                     Text(timeAgo(from: post.createdAt))
//                         .font(.caption)
//                         .foregroundColor(.gray)
//                 }
                
//                 // Content
//                 Text(post.content)
//                     .font(.body)
//                     .padding(.vertical)
                
//                 // Interaction Stats
//                 HStack(spacing: 20) {
//                     // Likes
//                     Button(action: handleLike) {
//                         HStack {
//                             Image(systemName: isLiked ? "heart.fill" : "heart")
//                                 .foregroundColor(isLiked ? .red : .gray)
//                             Text("\(likesCount)")
//                         }
//                     }
//                     .buttonStyle(BorderlessButtonStyle())
                    
//                     // Comments
//                     Button(action: { showingComments = true }) {
//                         HStack {
//                             Image(systemName: "bubble.right")
//                             Text("\(post.commentsCount)")
//                         }
//                     }
//                     .buttonStyle(BorderlessButtonStyle())
//                 }
//                 .foregroundColor(.gray)
                
//                 Divider()
                
//                 // Comments Section
//                 VStack(alignment: .leading, spacing: 12) {
//                     Text("Comments")
//                         .font(.headline)
//                         .padding(.top)
                    
//                     Button(action: { showingComments = true }) {
//                         Text("View all comments")
//                             .foregroundColor(.blue)
//                     }
//                 }
//             }
//             .padding()
//         }
//         .navigationBarTitleDisplayMode(.inline)
//         .sheet(isPresented: $showingComments) {
//             CommentsView(post: post)
//         }
//         .onAppear {
//             checkIfLiked()
//         }
//     }
    
//     private func checkIfLiked() {
//         guard let userId = Auth.auth().currentUser?.uid else { return }
        
//         let db = Firestore.firestore()
//         db.collection("posts").document(post.id)
//             .collection("likes").document(userId)
//             .getDocument { snapshot, error in
//                 if let error = error {
//                     print("Error checking like status: \(error.localizedDescription)")
//                     return
//                 }
//                 isLiked = snapshot?.exists ?? false
//             }
//     }
    
//     private func handleLike() {
//         guard let userId = Auth.auth().currentUser?.uid else { return }
        
//         let db = Firestore.firestore()
//         let postRef = db.collection("posts").document(post.id)
//         let likeRef = postRef.collection("likes").document(userId)
        
//         // Optimistically update UI
//         isLiked.toggle()
//         likesCount += isLiked ? 1 : -1
        
//         if isLiked {
//             likeRef.setData(["timestamp": FieldValue.serverTimestamp()]) { error in
//                 if let error = error {
//                     print("Error adding like: \(error.localizedDescription)")
//                     isLiked.toggle()
//                     likesCount -= 1
//                     return
//                 }
//                 postRef.updateData(["likes": FieldValue.increment(Int64(1))])
//             }
//         } else {
//             likeRef.delete { error in
//                 if let error = error {
//                     print("Error removing like: \(error.localizedDescription)")
//                     isLiked.toggle()
//                     likesCount += 1
//                     return
//                 }
//                 postRef.updateData(["likes": FieldValue.increment(Int64(-1))])
//             }
//         }
//     }
    
//     private func timeAgo(from date: Date) -> String {
//         let formatter = RelativeDateTimeFormatter()
//         formatter.unitsStyle = .abbreviated
//         return formatter.localizedString(for: date, relativeTo: Date())
//     }
// } 
