//
//  Like.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 3/2/25.
//

import Foundation
import FirebaseFirestore

struct Like: Identifiable {
    let id: String
    let userId: String
    let likedAt: Date
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.userId = data["userId"] as? String ?? ""
        self.likedAt = (data["likedAt"] as? Timestamp)?.dateValue() ?? Date()
    }
}
