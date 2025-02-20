//
//  NearbyRunnerCard.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 21/1/25.
//

import SwiftUI
import CoreLocation

struct NearbyRunnerCard: View {
    let user: UserApp
    let locationManager: LocationManager
    let action: () -> Void
    @State private var profileImage: UIImage?
    @State private var distance: String = ""
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    Group {
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .frame(width: 120, height: 160)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        if !distance.isEmpty {
                            Text(distance.isEmpty ? "Location unavailable" : "\(distance) away")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            LinearGradient(
                                gradient: Gradient(
                                    colors: [.clear, .black.opacity(0.7)]
                                ),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 40)
                            
                            Text(user.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(width: 120, height: 160)
                .clipped()
            }
            .frame(width: 120)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadProfileImage()
            calculateDistance()
        }
        .onChange(of: locationManager.location) { _ in
            calculateDistance()
        }
    }
    
    private func loadProfileImage() {
        guard let url = URL(string: user.profileImageUrl) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            }
        }.resume()
    }
    
    private func calculateDistance() {
        if let currentLocation = locationManager.location,
           let userLocation = user.locationAsCLLocation() {
            let distanceInMeters = currentLocation.distance(from: userLocation)
            distance = String(format: "%.1f km", distanceInMeters / 1000)
            print("Calculated distance: \(distance)")
        } else {
            print("Unable to calculate distance: currentLocation or userLocation is nil")
        }
    }
}


