import FirebaseFirestore

struct Message: Identifiable, Equatable {
    let id: String
    let conversationId: String
    let senderId: String
    let content: String
    let timestamp: Date
    let senderName: String
    let senderProfileUrl: String
    
    init(id: String, conversationId: String, senderId: String, content: String, 
         timestamp: Date, senderName: String, senderProfileUrl: String) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.timestamp = timestamp
        self.senderName = senderName
        self.senderProfileUrl = senderProfileUrl
    }
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.conversationId = data["conversationId"] as? String ?? ""
        self.senderId = data["senderId"] as? String ?? ""
        self.content = data["content"] as? String ?? ""
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        self.senderName = data["senderName"] as? String ?? ""
        self.senderProfileUrl = data["senderProfileUrl"] as? String ?? ""
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id &&
            lhs.conversationId == rhs.conversationId &&
            lhs.senderId == rhs.senderId &&
            lhs.content == rhs.content &&
            lhs.timestamp == rhs.timestamp &&
            lhs.senderName == rhs.senderName &&
            lhs.senderProfileUrl == rhs.senderProfileUrl
    }
} 
