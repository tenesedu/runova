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
    let userName: String
    let userProfileUrl: String?
    let timestamp: Date
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.userId = data["userId"] as? String ?? ""
        self.userName = data["userName"] as? String ?? ""
        self.userProfileUrl = data["userProfileUrl"] as? String
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
    }
}
