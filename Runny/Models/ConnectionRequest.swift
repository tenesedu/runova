import FirebaseFirestore

struct ConnectionRequest: Identifiable {
    let id: String
    let senderId: String
    let receiverId: String
    let status: String // "pending", "accepted", "rejected", "cancelled"
    let createdAt: Date
    let updatedAt: Date
    let senderName: String
    let senderProfileUrl: String
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.senderId = data["senderId"] as? String ?? ""
        self.receiverId = data["receiverId"] as? String ?? ""
        self.status = data["status"] as? String ?? "pending"
        self.senderName = data["senderName"] as? String ?? ""
        self.senderProfileUrl = data["senderProfileUrl"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
    }
} 