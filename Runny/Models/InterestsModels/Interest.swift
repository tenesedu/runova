import SwiftUI
import FirebaseFirestore

struct Interest: Identifiable {
    let id: String
    let name: String
    let iconName: String
    let backgroundImageUrl: String
    let description: String
    let color: Color
    var followersCount: Int
    var isFollowed: Bool
    
    let createdBy: String
    let createdAt: Date
    let adminId: String
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = data["name"] as? String ?? ""
        self.iconName = data["iconName"] as? String ?? ""
        self.backgroundImageUrl = data["backgroundImageUrl"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        self.followersCount = data["followersCount"] as? Int ?? 0
        self.isFollowed = false
        self.createdBy = data["createdBy"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.adminId = data["adminId"] as? String ?? ""
        
        if let colorHex = data["color"] as? String {
            self.color = Color(hex: colorHex)
        } else {
            self.color = .blue
        }
    }
} 
