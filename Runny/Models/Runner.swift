import Foundation

struct Runner: Identifiable {
    let id: String
    let profileImageUrl: String
    let name: String
    let gender: String
    let city: String
    let age: String
    let averagePace: String
    let goals: [String]
    let interests: [String]
    let isActive: Bool
    
    // Initialize Runner from User
       init(user: UserApp) {
           self.id = user.id
           self.profileImageUrl = user.profileImageUrl
           self.name = user.name
           self.gender = user.gender
           self.city = user.city
           self.age = user.age
           self.averagePace = user.averagePace
           self.goals = user.goals
           self.interests = user.interests
           self.isActive = user.isActive
       }
}

