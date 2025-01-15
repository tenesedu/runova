import Foundation

struct Conversation: Identifiable {
    let id: String
    let type: String // "direct" or "group"
    let participants: [String]
    let createdAt: Date
    let createdBy: String
    let lastMessage: String
    let lastMessageTime: Date
    let unreadCount: [String: Int]
    
    // Group-specific fields
    let groupName: String?
    let groupImageUrl: String?
    let groupDescription: String?
    let adminId: String?
    
    // Direct-specific fields
    let otherUserId: String?
    var otherUserProfile: Runner?
}