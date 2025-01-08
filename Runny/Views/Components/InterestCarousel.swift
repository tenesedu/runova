import SwiftUI

struct InterestCarousel: View {
    let interests: [Interest]
    @State private var showingAllInterests = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Running Interests")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showingAllInterests = true
                }) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 15) {
                    ForEach(interests.prefix(4)) { interest in
                        InterestCard(interest: interest)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 5)
            }
        }
        .sheet(isPresented: $showingAllInterests) {
            AllInterestsView(interests: interests)
        }
    }
}

struct InterestCard: View {
    let interest: Interest
    @State private var backgroundImage: UIImage?
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            // Background Image
            if let image = backgroundImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 200)
                    .clipped()
                    .cornerRadius(24) // Rounded corners
            }
            
            // Overlay for better contrast
            Color.black.opacity(0.4) // Semi-transparent overlay
            
            // Content
            VStack(spacing: 20) {
                // Icon Circle with Glass Effect
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .blur(radius: 4)
                        )
                    
                    Image(systemName: interest.iconName)
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.white)
                }
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                // Title
                Text(interest.name)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4)
            }
            .padding()
        }
        .frame(width: 160, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .onAppear {
            loadBackgroundImage()
        }
    }
    
    private func loadBackgroundImage() {
        guard let url = URL(string: interest.backgroundImageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.backgroundImage = image
                }
            }
        }.resume()
    }
} 
