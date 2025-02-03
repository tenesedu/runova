import FirebaseFirestore
import SwiftUI

struct Post: Identifiable {
    let id: String
    let userId: String
    let userName: String
    let userProfileUrl: String?
    let title: String
    let content: String
    let interest: String
    let interestColor: Color
    let timestamp: Date
    var likes: Int
    var comments: Int
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.userId = data["userId"] as? String ?? ""
        self.userName = data["userName"] as? String ?? ""
        self.userProfileUrl = data["userProfileUrl"] as? String ?? nil
        self.title = data["title"] as? String ?? ""
        self.content = data["content"] as? String ?? ""
        self.interest = data["interest"] as? String ?? ""
        self.interestColor = Color(hex: data["interestColor"] as? String ?? "#007AFF")
        self.likes = data["likes"] as? Int ?? 0
        self.comments = data["comments"] as? Int ?? 0
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
    }
} 