//
//  UserProfile.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 21/1/25.
//

import Foundation

struct UserProfile: Identifiable {
    let id: String
    let name: String
    let profileImageUrl: String
    
    init(id: String, name: String, profileImageUrl: String) {
        self.id = id
        self.name = name
        self.profileImageUrl = profileImageUrl
    }
    
    init(user: UserApp){
        self.id = user.id
        self.name = user.name
        self.profileImageUrl = user.profileImageUrl
    }
    
    init(runner: Runner){
        self.id = runner.id
        self.name = runner.name
        self.profileImageUrl = runner.profileImageUrl
    }

}
