import Foundation
import FirebaseCore
struct Event: Identifiable {
    let id: String
    let name: String
    let description: String
    let imageUrl: String
    let date: Date
    let time: String
    let location: String
    let city: String
    let distance: Double
    let type: String
    let price: Double
    let organizerName: String
    let organizerContact: String
    let maxParticipants: Int
    let currentParticipants: Int
    let status: String
    let difficulty: String
    let terrain: String
    let amenities: [String]
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = data["name"] as? String ?? "Unknown Event"
        self.description = data["description"] as? String ?? ""
        self.imageUrl = data["imageUrl"] as? String ?? ""
        self.date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
        self.time = data["time"] as? String ?? ""
        self.location = data["location"] as? String ?? ""
        self.city = data["city"] as? String ?? ""
        self.distance = data["distance"] as? Double ?? 0.0
        self.type = data["type"] as? String ?? ""
        self.price = data["price"] as? Double ?? 0.0
        self.organizerName = data["organizerName"] as? String ?? ""
        self.organizerContact = data["organizerContact"] as? String ?? ""
        self.maxParticipants = data["maxParticipants"] as? Int ?? 0
        self.currentParticipants = data["currentParticipants"] as? Int ?? 0
        self.status = data["status"] as? String ?? "upcoming"
        self.difficulty = data["difficulty"] as? String ?? "beginner"
        self.terrain = data["terrain"] as? String ?? "road"
        self.amenities = data["amenities"] as? [String] ?? []
    }
} 
