import FirebaseFirestore

struct ConnectionRequest: Identifiable {
    let id: String
    let senderId: String
    let receiverId: String
    let status: String // "pending", "accepted", "rejected", "cancelled"
    let createdAt: Date
    let updatedAt: Date
    
    init(id: String = "", senderId: String, receiverId: String, status: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.senderId = data["senderId"] as? String ?? ""
        self.receiverId = data["receiverId"] as? String ?? ""
        self.status = data["status"] as? String ?? "pending"
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "senderId": senderId,
            "receiverId": receiverId,
            "status": status,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
}
