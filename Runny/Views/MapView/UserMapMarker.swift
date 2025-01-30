//
//  UserMapMaker.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 21/1/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserMapMarker: View {
    let user: UserApp
    let action: () -> Void
    @State private var profileImage: UIImage?
    
    var isCurrentUser: Bool {
        user.id == Auth.auth().currentUser?.uid
    }
    
    var body: some View {
        Button(action: {
            if !isCurrentUser {
                action()
            }
        }) {
            VStack(spacing: 4) {
                Group {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                            )
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isCurrentUser ? Color.blue : Color.white, lineWidth: 3)
                )
                .shadow(radius: 3)
                
                Text(isCurrentUser ? NSLocalizedString("You", comment: "") : user.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .shadow(radius: 1)
                    )
            }
        }
        .onAppear {
            loadProfileImage()
        }
    }
    
    private func loadProfileImage() {
        guard let url = URL(string: user.profileImageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            }
        }.resume()
    }
}


import SwiftUI

struct UserMapMarker_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Preview for the current user
            UserMapMarker(
                user: UserApp(
                    id: "currentUser",
                    data: [
                        "profileImageUrl": "https://example.com/currentUser.jpg",
                        "name": "You",
                        "gender": "Male",
                        "city": "San Francisco",
                        "age": "28",
                        "averagePace": "5:30/km",
                        "goals": ["Run a marathon", "Improve pace"],
                        "interests": ["Trail running", "Yoga"],
                        "location": GeoPoint(latitude: 37.7749, longitude: -122.4194),
                        "lastLocationUpdate": Timestamp(date: Date()),
                        "conversations": [],
                        "friends": []
                    ]
                ),
                action: {
                    print("Current user tapped")
                }
            )
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Preview for another runner with a profile image
            UserMapMarker(
                user: UserApp(
                    id: "runner1",
                    data: [
                        "profileImageUrl": "https://example.com/runner1.jpg",
                        "name": "Alice",
                        "gender": "Female",
                        "city": "New York",
                        "age": "25",
                        "averagePace": "6:00/km",
                        "goals": ["Run 5km without stopping"],
                        "interests": ["Cycling", "Meditation"],
                        "location": GeoPoint(latitude: 37.7750, longitude: -122.4195),
                        "lastLocationUpdate": Timestamp(date: Date()),
                        "conversations": [],
                        "friends": []
                    ]
                ),
                action: {
                    print("Alice tapped")
                }
            )
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Preview for another runner without a profile image
            UserMapMarker(
                user: UserApp(
                    id: "runner2",
                    data: [
                        "profileImageUrl": "",
                        "name": "Bob",
                        "gender": "Male",
                        "city": "Los Angeles",
                        "age": "30",
                        "averagePace": "5:45/km",
                        "goals": ["Lose weight", "Run a half marathon"],
                        "interests": ["Weightlifting", "Hiking"],
                        "location": GeoPoint(latitude: 37.7760, longitude: -122.4196),
                        "lastLocationUpdate": Timestamp(date: Date()),
                        "conversations": [],
                        "friends": []
                    ]
                ),
                action: {
                    print("Bob tapped")
                }
            )
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
