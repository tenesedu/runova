import SwiftUI
import FirebaseFirestore

struct Interest: Identifiable {
    let id: String
    let name: String
    let iconName: String
    let backgroundImageUrl: String
    let color: Color
    var followersCount: Int
    var isFollowed: Bool
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = data["name"] as? String ?? ""
        self.iconName = data["iconName"] as? String ?? ""
        self.backgroundImageUrl = data["backgroundImageUrl"] as? String ?? ""
        self.followersCount = data["followersCount"] as? Int ?? 0
        self.isFollowed = false // Will be updated when checking follow status
        
        if let colorHex = data["color"] as? String {
            self.color = Color(hex: colorHex)
        } else {
            self.color = .blue
        }
    }
} 
