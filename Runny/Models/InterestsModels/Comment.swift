//
//  Comment.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 3/2/25.
//

import Foundation
import FirebaseFirestore

struct Comment: Identifiable {
    let id: String
    let text: String
    let userId: String
    let userName: String
    let userImageUrl: String
    let createdAt: Date
    let parentId: String?
    let postId: String
    var replies: [Comment] = []
    var likesCount: Int
    var isLiked: Bool = false
    
    init(id: String, data: [String: Any], postId: String) {
        self.id = id
        self.text = data["text"] as? String ?? ""
        self.userId = data["userId"] as? String ?? ""
        self.userName = data["userName"] as? String ?? ""
        self.userImageUrl = data["userImageUrl"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.parentId = data["parentId"] as? String
        self.postId = postId
        self.likesCount = data["likesCount"] as? Int ?? 0
    }
}
