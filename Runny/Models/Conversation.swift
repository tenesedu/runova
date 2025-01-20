import Foundation

struct Conversation: Identifiable {
    let id: String
    let type: String // "direct" or "group"
    let participants: [String]
    let createdAt: Date
    let createdBy: String
    var lastMessage: String
    var lastMessageTime: Date
    var lastMessageSenderId: String?
    var unreadCount: [String: Int]
    
    // Group-specific fields
    var groupName: String?
    var groupImageUrl: String?
    var groupDescription: String?
    var adminId: String?
    
    // Direct-specific fields
    var otherUserId: String?
    var otherUserProfile: Runner?
    
    let deletedFor: [String: Bool]
    let deletedAt: [String: Date]
    
    init(id: String, type: String, participants: [String], createdAt: Date, createdBy: String,
         lastMessage: String, lastMessageTime: Date, lastMessageSenderId: String?, unreadCount: [String: Int],
         groupName: String?, groupImageUrl: String?, groupDescription: String?, adminId: String?,
         otherUserId: String?, deletedFor: [String: Bool] = [:], deletedAt: [String: Date] = [:]) {
        self.id = id
        self.type = type
        self.participants = participants
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.lastMessageSenderId = lastMessageSenderId
        self.unreadCount = unreadCount
        self.groupName = groupName
        self.groupImageUrl = groupImageUrl
        self.groupDescription = groupDescription
        self.adminId = adminId
        self.otherUserId = otherUserId
        self.deletedFor = deletedFor
        self.deletedAt = deletedAt
    }
}
