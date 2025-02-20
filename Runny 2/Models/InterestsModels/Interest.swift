import SwiftUI
import FirebaseFirestore

struct Interest: Identifiable {
    let id: String
    var name: String
    var iconName: String
    var backgroundImageUrl: String
    var description: String
    var color: Color
    var followerCount: Int
    var isFollowed: Bool
    
    let createdBy: String
    let createdAt: Date
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = data["name"] as? String ?? ""
        self.iconName = data["iconName"] as? String ?? ""
        self.backgroundImageUrl = data["backgroundImageUrl"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        self.followerCount = data["followerCount"] as? Int ?? 0
        self.isFollowed = false
        self.createdBy = data["createdBy"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        
        if let colorHex = data["color"] as? String {
            self.color = Color(hex: colorHex)
        } else {
            self.color = .blue
        }
    }
} 
