import SwiftUI

public struct UserProfile: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let age: String
    public let averagePace: String
    public let city: String
    public let profileImageUrl: String
    public let gender: String
    public var profileImage: UIImage?
    
    public init(id: String, name: String, age: String, averagePace: String, city: String, profileImageUrl: String, gender: String, profileImage: UIImage? = nil) {
        self.id = id
        self.name = name
        self.age = age
        self.averagePace = averagePace
        self.city = city
        self.profileImageUrl = profileImageUrl
        self.gender = gender
        self.profileImage = profileImage
    }
    
    public static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }
} 