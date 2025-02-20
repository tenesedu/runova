import Foundation
import FirebaseFirestore

struct JoinRequest: Identifiable {
    let id: String
    let userId: String
    let userName: String
    let userImage: String
    let status: String
    let timestamp: Date
    
    init(id: String = UUID().uuidString,
         status: String,
         userId: String,
         userName: String,
         userImage: String,
         timestamp: Date) {
        self.id = id
        self.status = status
        self.userId = userId
        self.userName = userName
        self.userImage = userImage
        self.timestamp = timestamp
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "status": status,
            "userId": userId,
            "userName": userName,
            "userImage": userImage,
            "timestamp": Timestamp(date: timestamp)
        ]
    }
}
