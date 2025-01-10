import FirebaseFirestore

struct Run: Identifiable {
    let id: String
    let name: String
    let description: String
    let time: Date
    let location: String
    let maxParticipants: Int
    let currentParticipants: [String]
    let distance: Double
    let averagePace: String
    let terrain: String
    let createdBy: String
    let createdAt: Date
    let title: String
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = data["name"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        self.time = (data["time"] as? Timestamp)?.dateValue() ?? Date()
        self.location = data["location"] as? String ?? ""
        self.maxParticipants = data["maxParticipants"] as? Int ?? 0
        self.currentParticipants = data["currentParticipants"] as? [String] ?? []
        self.distance = data["distance"] as? Double ?? 0.0
        self.averagePace = data["averagePace"] as? String ?? ""
        self.terrain = data["terrain"] as? String ?? ""
        self.createdBy = data["createdBy"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.title = data["title"] as? String ?? ""
    }
} 