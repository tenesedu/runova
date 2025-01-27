import Foundation

struct JoinRequest:  Identifiable{
    let id: String
    let status: String
    let userId: String
    let userName: String?
    let userImage: String?
    let timestamp: Date
    
    init(id: String, status: String, userId: String, userName: String?, userImage: String?, timestamp: Date) {
        self.id = id
        self.status = status
        self.userId = userId
        self.userName = userName
        self.userImage = userImage
        self.timestamp = timestamp
    }
}
