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
    let createdBy: String
    let userName: String
    let userProfileUrl: String?
    let content: String
    let timestamp: Date
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.createdBy = data["createdBy"] as? String ?? ""
        self.userName = data["userName"] as? String ?? ""
        self.userProfileUrl = data["userProfileUrl"] as? String
        self.content = data["content"] as? String ?? ""
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
    }
}
