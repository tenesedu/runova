import SwiftUI

struct Interest: Identifiable {
    let id: String
    let name: String
    let iconName: String
    let color: Color
    let backgroundImageUrl: String
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = data["name"] as? String ?? ""
        self.iconName = data["iconName"] as? String ?? "figure.run"
        self.color = Color(hex: data["color"] as? String ?? "#007AFF")
        self.backgroundImageUrl = data["backgroundImageUrl"] as? String ?? ""
    }
} 
