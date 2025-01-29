//
//  AllRunnersView.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 29/1/25.
//

import SwiftUI
import FirebaseAuth

struct AllRunnersView: View {
    let runners: [Runner]
    let users: [UserApp]
    let locationManager: LocationManager

    @Environment(\.dismiss) private var dismiss

    var sortedRunners: [Runner] {
        guard let currentLocation = locationManager.location else { return runners }
        
        return users
            .filter { user in
                user.id != Auth.auth().currentUser?.uid
            }
            .sorted { user1, user2 in
                guard let location1 = user1.locationAsCLLocation(),
                      let location2 = user2.locationAsCLLocation() else {
                    return false
                }
                let distance1 = currentLocation.distance(from: location1)
                let distance2 = currentLocation.distance(from: location2)
                return distance1 < distance2
            }
            .map { Runner(user: $0) }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sortedRunners) { runner in
                    NavigationLink(destination: RunnerDetailView(runner: runner)) {
                        HStack(spacing: 16) {
                            // Add ZStack to overlay active status on profile image
                            ZStack(alignment: .topTrailing) {
                                AsyncImage(url: URL(string: runner.profileImageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                
                                // Active status indicator
                                Circle()
                                    .fill(runner.isActive ? Color.green : Color.gray)
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .offset(x: 3, y: -3)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(runner.name)
                                    .font(.headline)
                                
                                if let userLocation = users.first(where: { $0.id == runner.id })?.locationAsCLLocation(),
                                   let currentLocation = locationManager.location {
                                    Text(String(format: "%.1f km away", currentLocation.distance(from: userLocation) / 1000))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Text(runner.city)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("All Runners", comment: ""))
        .navigationBarItems(trailing: Button("Done") {
            dismiss()
        })
    }
}
