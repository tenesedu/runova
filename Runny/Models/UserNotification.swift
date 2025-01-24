import FirebaseFirestore

struct UserNotification: Identifiable {
    let id: String
    let type: NotificationType
    let senderId: String
    let receiverId: String
    let timestamp: Date
    let read: Bool
    let senderName: String
    let senderProfileUrl: String
    let relatedDocumentId: String? // Optional
    
    enum NotificationType: String, Codable {
        case friendRequest = "friend_request"
        case friendAccepted = "friend_accepted"
        case messageReceived = "message_received"
        case eventInvitation = "event_invitation"
    }
    
    var message: String {
        switch type {
        case .friendRequest:
            return "\(senderName) sent you a friend request"
        case .friendAccepted:
            return "\(senderName) accepted your friend request"
            
        case .messageReceived:
            return "\(senderName) sent you a message"
        case .eventInvitation:
            return "\(senderName) invited you to an event"
        }
    }
    
    init(
           type: NotificationType,
           senderId: String,
           receiverId: String,
           timestamp: Date = Date(),
           read: Bool = false,
           senderName: String,
           senderProfileUrl: String,
           relatedDocumentId: String? = nil
       ) {
           self.id = "" // This will be set when fetching from Firestore
           self.type = type
           self.senderId = senderId
           self.receiverId = receiverId
           self.timestamp = timestamp
           self.read = read
           self.senderName = senderName
           self.senderProfileUrl = senderProfileUrl
           self.relatedDocumentId = relatedDocumentId
       }
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.type = NotificationType(rawValue: data["type"] as? String ?? "") ?? .friendRequest
        self.senderId = data["senderId"] as? String ?? ""
        self.receiverId = data["receiverId"] as? String ?? ""
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        self.read = data["read"] as? Bool ?? false
        self.senderName = data["senderName"] as? String ?? ""
        self.senderProfileUrl = data["senderProfileUrl"] as? String ?? ""
        self.relatedDocumentId = data["relatedDocumentId"] as? String
    }
} 
