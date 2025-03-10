//
//  PostService.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 9/3/25.
//
import FirebaseFirestore

class PostService {
    static let shared = PostService()
    private let db = Firestore.firestore()
    
    
    func checkIfPostLiked(postId: String, completion: @escaping (Bool) -> Void) {
        guard let userId = UserManager.shared.currentUser?.id else {
            print("No authenticated user")
            completion(false)
            return
        }
        db.collection("posts").document(postId)
            .collection("likes").document(userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error checking like status: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(snapshot?.exists ?? false)
                    print("Post is liked = true.")
                }
            }
    }
    
    func togglePostLike(postId: String, completion: @escaping (Bool, Int) -> Void) {
        guard let userId = UserManager.shared.currentUser?.id else {
            print("No authenticated user")
            return
        }
        
        let likeRef = db.collection("posts").document(postId)
            .collection("likes").document(userId)
        
        let createdAt = Timestamp(date: Date())
        
        // Primero verificamos si el post está liked
        likeRef.getDocument { (snapshot, error) in
            let isCurrentlyLiked = snapshot?.exists ?? false
            
            if isCurrentlyLiked {
                // Unlike
                likeRef.delete { error in
                    if let error = error {
                        print("Error removing like from post: \(error.localizedDescription)")
                    } else {
                        self.updatePostLikesCount(postId: postId, increment: false) { newCount in
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
                        print("Error liking post: \(error.localizedDescription)")
                    } else {
                        self.updatePostLikesCount(postId: postId, increment: true) { newCount in
                            completion(true, newCount)
                        }
                    }
                }
            }
        }
    }
    
    private func updatePostLikesCount(postId: String, increment: Bool, completion: @escaping (Int) -> Void) {
        let postRef = db.collection("posts").document(postId)
        
        postRef.updateData([
            "likesCount": FieldValue.increment(increment ? Int64(1) : Int64(-1))
        ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            }
            
            // Obtener el nuevo conteo
            postRef.getDocument { (document, error) in
                if let document = document, let likesCount = document.data()?["likesCount"] as? Int {
                    completion(likesCount)
                }
            }
        }
    }
}
