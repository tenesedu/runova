import FirebaseFirestore

struct Message: Identifiable {
    let id: String
    let senderId: String
    let receiverId: String
    let content: String
    let timestamp: Date
    var senderName: String
    var senderProfileUrl: String?
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.senderId = data["senderId"] as? String ?? ""
        self.receiverId = data["receiverId"] as? String ?? ""
        self.content = data["content"] as? String ?? ""
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        self.senderName = data["senderName"] as? String ?? ""
        self.senderProfileUrl = data["senderProfileUrl"] as? String
    }
} 