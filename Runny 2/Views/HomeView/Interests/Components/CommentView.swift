//
//  CommentView.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 12/2/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CommentView: View {
    let comment: Comment
    @State private var newComment = ""
    @State private var comments: [Comment] = []
    @FocusState private var isCommentFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                // Lista de comentarios
                List(comments) { comment in
                    CommentRow(comment: comment)
                }
                
                // Input para añadir un nuevo comentario
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
                    
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(.roundedBorder)
                        .focused($isCommentFocused)
                    
                    if !newComment.isEmpty {
                        Button(action: postComment) {
                            Text("Post")
                                .foregroundColor(.blue)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // Cierra el sheet
                    }
                }
            }
            .onAppear {
                //fetchComments()
            }
        }
    }
    
    // private func fetchComments() {
    //     let db = Firestore.firestore()
    //     db.collection("comments")
    //         .whereField("parentID", isEqualTo: post.id)
    //         .order(by: "createdAt", descending: false)
    //         .getDocuments { snapshot, error in
    //             if let documents = snapshot?.documents {
    //                 self.comments = documents.compactMap { doc in
    //                     let data = doc.data()
    //                     return Comment(
    //                         id: doc.documentID,
    //                         parentID: data["parentID"] as? String ?? "",
    //                         text: data["text"] as? String ?? "",
    //                         userId: data["userId"] as? String ?? "",
    //                         userName: data["userName"] as? String ?? "",
    //                         userImageUrl: data["userImageUrl"] as? String ?? "",
    //                         createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
    //                         likesCount: data["likesCount"] as? Int ?? 0
    //                     )
    //                 }
    //             }
    //         }
    // }
    
    private func postComment() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let userData = snapshot?.data(),
                  let userName = userData["name"] as? String,
                  let userImageUrl = userData["profileImageUrl"] as? String else { return }
            
            let commentData: [String: Any] = [
                //"parentID": post.id,
                "text": newComment,
                "userId": userId,
                "userName": userName,
                "userImageUrl": userImageUrl,
                "createdAt": FieldValue.serverTimestamp(),
                "likesCount": 0
            ]
            
            db.collection("comments").addDocument(data: commentData) { error in
                if error == nil {
                    // Actualiza el contador de comentarios en el post
                    /*
                    db.collection("posts").document(post.id)
                        .updateData(["commentsCount": FieldValue.increment(Int64(1))])
                    newComment = ""
                    //fetchComments() // Recarga los comentarios*/
                }
            }
        }
    }
}

let mockPostId = "post123" // ID del post al que pertenecen los comentarios

let mockComments: [Comment] = [
    Comment(
        id: "comment1",
        data: [
            "text": "Este es un comentario principal.",
            "userId": "user1",
            "userName": "iOSDev",
            "userImageUrl": "https://example.com/profile1.jpg",
            "createdAt": Timestamp(date: Date()),
            "parentId": nil, // Es un comentario principal
            "mentionedUserName": nil,
            "likesCount": 5
        ],
        postId: mockPostId
    ),
    Comment(
        id: "comment2",
        data: [
            "text": "@iOSDev Esta es una respuesta a tu comentario.",
            "userId": "user2",
            "userName": "Reactivo",
            "userImageUrl": "https://example.com/profile2.jpg",
            "createdAt": Timestamp(date: Date()),
            "parentId": "comment1", // Respuesta al comentario 1
            "mentionedUserName": "iOSDev",
            "likesCount": 3
        ],
        postId: mockPostId
    ),
    Comment(
        id: "comment3",
        data: [
            "text": "Otro comentario principal.",
            "userId": "user3",
            "userName": "AppleFan",
            "userImageUrl": "https://example.com/profile3.jpg",
            "createdAt": Timestamp(date: Date()),
            "parentId": nil, // Es un comentario principal
            "mentionedUserName": nil,
            "likesCount": 2
        ],
        postId: mockPostId
    )
]
#Preview {
    CommentView(comment: mockComments[0])
}
