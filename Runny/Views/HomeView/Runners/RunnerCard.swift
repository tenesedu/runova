//
//  RunnerCard.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 29/1/25.
//

import SwiftUI

struct RunnerCard: View {
    let runner: Runner
    @State private var profileImage: UIImage?
    @State private var showingDetail = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Profile Image Section
                ZStack(alignment: .bottomLeading) {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(height: 100)
                            .overlay(
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50)
                                    .foregroundColor(.white.opacity(0.8))
                            )
                    }
                    
                    // Gradient Overlay
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .black.opacity(0.3)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                
                // Runner Info Section
                VStack(alignment: .leading, spacing: 12) {
                    // Name and Age
                    HStack {
                        Text(runner.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(runner.age)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Location and Stats
                    VStack(spacing: 8) {
                        // Location
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text(runner.city)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Pace
                        HStack {
                            Image(systemName: "speedometer")
                                .foregroundColor(.blue)
                            Text("\(runner.averagePace) min/km")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            }
            .frame(width: 160)
            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            NavigationView {
                RunnerDetailView(runner: runner)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingDetail = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            if !runner.profileImageUrl.isEmpty {
                loadProfileImage()
            }
        }
    }
    
    private func loadProfileImage() {
        guard let url = URL(string: runner.profileImageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            }
        }.resume()
    }
}
