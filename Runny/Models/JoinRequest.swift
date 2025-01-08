import Foundation

struct JoinRequest: Identifiable {
    let id: String
    let userId: String
    let userName: String
    let userImage: String?
    let timestamp: Date
} 