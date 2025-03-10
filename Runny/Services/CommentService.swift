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
    
    func checkIfCommentLiked(postId: String, commentId: String, completion: @escaping (Bool) -> Void) {
        guard let userId = UserManager.shared.currentUser?.id else {
            print("No authenticated user")
            completion(false)
            return
        }
        db.collection("posts").document(postId)
            .collection("comments").document(commentId)
            .collection("likes").document(userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error checking like status: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(snapshot?.exists ?? false)
                    print("Comment is liked = \(snapshot?.exists ?? false).")
                }
            }
    }
    
    func toggleCommentLike(postId: String, commentId: String, completion: @escaping (Bool, Int) -> Void) {
        guard let userId = UserManager.shared.currentUser?.id else {
            print("No authenticated user")
            return
        }
        
        let likeRef = db.collection("posts").document(postId)
            .collection("comments").document(commentId)
            .collection("likes").document(userId)
        
        let createdAt = Timestamp(date: Date())
        
        likeRef.getDocument { (snapshot, error) in
            let isCurrentlyLiked = snapshot?.exists ?? false
            
            if isCurrentlyLiked {
                // Unlike
                likeRef.delete { error in
                    if let error = error {
                        print("Error removing like from comment: \(error.localizedDescription)")
                        completion(false, 0)
                    } else {
                        self.updateCommentLikesCount(postId: postId, commentId: commentId, increment: false) { newCount in
                            completion(false, newCount)
                        }
                    }
                }
            } else {
                // Like
                likeRef.setData([
                    "createdAt": createdAt
                ]) { error in
                    if let error = error {
                        print("Error liking comment: \(error.localizedDescription)")
                        completion(false, 0)
                    } else {
                        self.updateCommentLikesCount(postId: postId, commentId: commentId, increment: true) { newCount in
                            completion(true, newCount)
                        }
                    }
                }
            }
        }
    }

    private func updateCommentLikesCount(postId: String, commentId: String, increment: Bool, completion: @escaping (Int) -> Void) {
        let commentRef = db.collection("posts").document(postId)
            .collection("comments").document(commentId)
        
        // Actualizamos el contador de likes en Firestore para el comentario
        commentRef.updateData([
            "likesCount": FieldValue.increment(increment ? Int64(1) : Int64(-1))
        ]) { error in
            if let error = error {
                print("Error updating comment likes count: \(error)")
                completion(0)  // Regresamos un contador de 0 si hubo un error
                return
            }
            
            // Obtener el nuevo conteo de likes del comentario
            commentRef.getDocument { (document, error) in
                if let document = document, let likesCount = document.data()?["likesCount"] as? Int {
                    completion(likesCount)  // Regresamos el nuevo conteo de likes
                } else {
                    print("Error fetching updated comment likes count")
                    completion(0)  // Regresamos 0 si no podemos obtener el nuevo conteo
                }
            }
        }
    }

    
 
}
