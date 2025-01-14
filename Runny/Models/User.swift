import Foundation
import FirebaseFirestore
import CoreLocation

struct User: Identifiable {
    let id: String
    let profileImageUrl: String
    let name: String
    let gender: String
    let city: String
    let age: String
    let averagePace: String
    let goals: [String]
    let interests: [String]
    let location: GeoPoint?
    let lastLocationUpdate: Date?
    
    var isActive: Bool {
        guard let lastUpdate = lastLocationUpdate else { return false }
        let hourAgo = Date().addingTimeInterval(-3600) // 1 hour ago
        return lastUpdate > hourAgo
    }
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
        self.name = data["name"] as? String ?? "Unknown"
        self.gender = data["gender"] as? String ?? "Not specified"
        self.city = data["city"] as? String ?? "Unknown"
        self.age = data["age"] as? String ?? "N/A"
        self.averagePace = data["averagePace"] as? String ?? "N/A"
        self.goals = data["goals"] as? [String] ?? []
        self.interests = data["interests"] as? [String] ?? []
        self.location = data["location"] as? GeoPoint
        
        if let timestamp = data["lastLocationUpdate"] as? Timestamp {
            self.lastLocationUpdate = timestamp.dateValue()
        } else {
            self.lastLocationUpdate = nil
        }
    }
    
    func locationAsCLLocation() -> CLLocation? {
        guard let location = location else { return nil }
        return CLLocation(latitude: location.latitude, longitude: location.longitude)
    }
}
