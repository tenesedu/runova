//
//  CommentService.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 9/3/25.
//

import FirebaseFirestore

class CommentService {
    static let shared = CommentService()
    private let db = Firestore.firestore()
    
    func fetchComments(for postId: String, completion: @escaping ([Comment]) -> Void) {
        db.collection("posts").document(postId).collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching comments: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    completion([])
                    return
                }
                
                let comments = documents.map { document in
                    Comment(id: document.documentID, 
                           data: document.data(),
                           postId: postId)
                }
                
                print("Fetched \(comments.count) comments for post \(postId)")
                completion(comments)
            }
    }
        
    
    func addComment(textComment: String, userId: String, parentId: String, to postId: String, completion: @escaping (Error?) -> Void) {
        let commentData: [String: Any] = [
            "text": textComment,
            "userId": userId,
            "createdAt": FieldValue.serverTimestamp(),
            "parentId": parentId,
            "likesCount": 0,
            "repliesCount": 0
        ]
        
        db.collection("posts").document(postId)
            .collection("comments")
            .addDocument(data: commentData) { error in
                if let error = error {
                    print("Error adding comment: \(error.localizedDescription)")
                }else {
                    self.db.collection("posts").document(postId)
                        .updateData(["commentsCount": FieldValue.increment(Int64(1))])
                }
                completion(error)
            }
    }
}
