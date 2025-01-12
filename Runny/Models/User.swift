import Foundation
import FirebaseFirestore
import CoreLocation

struct User: Identifiable {
    let id: String
    let name: String
    let profileImageUrl: String
    let latitude: Double
    let longitude: Double
    let lastLocationUpdate: Date
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = data["name"] as? String ?? "Unknown"
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
        self.latitude = data["latitude"] as? Double ?? 0
        self.longitude = data["longitude"] as? Double ?? 0
        self.lastLocationUpdate = (data["lastLocationUpdate"] as? Timestamp)?.dateValue() ?? Date()
    }
} 