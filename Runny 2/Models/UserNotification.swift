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
    let runId: String?
    
    enum NotificationType: String, Codable {
        case friendRequest = "friend_request"
        case friendAccepted = "friend_accepted"
        case joinRequest = "join_request"
        case joinRequestAccepted = "join_request_accepted"
     
    }
    
    var message: String {
        let senderPlaceholder = senderName
        switch type {
        case .friendRequest:
            return String(format: NSLocalizedString("friendRequest", comment: ""), senderPlaceholder)
        case .friendAccepted:
            return String(format: NSLocalizedString("friendAccepted", comment: ""), senderPlaceholder)
        case .joinRequest:
            return String(format: NSLocalizedString("joinRequest", comment: ""), senderPlaceholder)
        case .joinRequestAccepted:
            return String(format: NSLocalizedString("joinRequestAccepted", comment: ""), senderPlaceholder)
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
           relatedDocumentId: String? = nil,
           runId: String? = nil
       ) {
           self.id = "" 
           self.type = type
           self.senderId = senderId
           self.receiverId = receiverId
           self.timestamp = timestamp
           self.read = read
           self.senderName = senderName
           self.senderProfileUrl = senderProfileUrl
           self.relatedDocumentId = relatedDocumentId
           self.runId = runId
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
        self.runId = data["runId"] as? String
    }
} 
