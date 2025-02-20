//
//  Follower.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 3/2/25.
//

import FirebaseFirestore
import SwiftUI

struct Follower {
    let id: String
    let userId: String
    let followedAt: Date
    let role: String
    
    init(id: String, data: [String: Any]){
        self.id = id
        self.userId = data["userId"] as! String
        self.followedAt = (data["followedAt"] as? Timestamp)?.dateValue() ?? Date()
        self.role = data["role"] as! String
    }
}
