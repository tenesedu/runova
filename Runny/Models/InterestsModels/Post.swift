import FirebaseFirestore
import SwiftUI

struct Post: Identifiable {
    let id: String
    let content: String
    let interestId: String
    let interestName: String
    let createdAt: Date
    let createdBy: String
    let creatorName: String
    let creatorImageUrl: String
    let likesCount: Int
    let commentsCount: Int
    let imagesUrls: [String?]
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.content = data["content"] as? String ?? ""
        self.interestId = data["interestId"] as? String ?? ""
        self.interestName = data["interestName"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.createdBy = data["createdBy"] as? String ?? ""
        self.creatorName = data["creatorName"] as? String ?? ""
        self.creatorImageUrl = data["creatorImageUrl"] as? String ?? ""
        self.likesCount = data["likesCount"] as? Int ?? 0
        self.commentsCount = data["commentsCount"] as? Int ?? 0
        self.imagesUrls = data["imagesUrls"] as? [String] ?? []
    }
}
