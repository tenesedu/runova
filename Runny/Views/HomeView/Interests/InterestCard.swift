import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct InterestCard: View {
    let interest: Interest
    @State private var isFollowing: Bool
    @State private var followerCount: Int
    let onFollowToggle: () -> Void
    let cardWidth: CGFloat = 280
    let cardHeight: CGFloat = 180
    
    init(interest: Interest, onFollowToggle: @escaping () -> Void) {
        self.interest = interest
        self._isFollowing = State(initialValue: interest.isFollowed)
        self._followerCount = State(initialValue: interest.followerCount)
        self.onFollowToggle = onFollowToggle
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Navigation Link for the whole card except the follow button
            NavigationLink(destination: InterestDetailView(interest: interest)) {
                ZStack(alignment: .bottomLeading) {
                    // Background Image
                    AsyncImage(url: URL(string: interest.backgroundImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray
                    }
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
                    
                    // Gradient Overlay
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content overlay
            VStack(alignment: .leading, spacing: 12) {
                // Title and Followers Row
                HStack(alignment: .center) {
                    // Icon and Title
                    HStack(spacing: 8) {
                        Image(systemName: interest.iconName)
                            .font(.title3)
                            .foregroundColor(interest.color)
                        
                        Text(interest.name.localized)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Followers Count
                    Text(String(format: NSLocalizedString("%d followers", comment: ""), followerCount))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Follow Button
                Button(action: {
                    toggleFollow()
                    onFollowToggle()
                }) {
                    Text(isFollowing ? NSLocalizedString("Following", comment: "") :  NSLocalizedString("Follow", comment: ""))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isFollowing ? interest.color.opacity(0.2) : interest.color)
                        .foregroundColor(isFollowing ? interest.color : .white)
                        .clipShape(Capsule())
                }
            }
            .padding(16)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 5)
        .onAppear {
            checkFollowStatus()
        }
    }
    
    private func checkFollowStatus() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let interestRef = db.collection("interests").document(interest.id)

        // Listen for real-time updates
        interestRef.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error checking follow status: \(error.localizedDescription)")
                return
            }

            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    self.followerCount = data["followerCount"] as? Int ?? 0
                }
            }
        }

        // Listen for user's follow status
        db.collection("interests").document(interest.id)
            .collection("followers").document(userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error checking follow status: \(error.localizedDescription)")
                    return
                }
                DispatchQueue.main.async {
                    self.isFollowing = snapshot?.exists ?? false
                }
            }
    }

    
    private func toggleFollow() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let interestRef = db.collection("interests").document(interest.id)
        let followerRef = db.collection("interests").document(interest.id).collection("followers").document(userId)
        
        if isFollowing {
            followerRef.delete { error in
                if let error = error {
                    print("Error unfollowing interest: \(error.localizedDescription)")
                    return
                }
                
                interestRef.updateData(["followerCount": FieldValue.increment(Int64(-1))])
                followerCount -= 1
                isFollowing.toggle()
            }
           
        }else {
            let followerData: [String : Any] = [
                "userId": userId,
                "followedAt": FieldValue.serverTimestamp(),
                "role": "member"
            ]
                                               
            followerRef.setData(followerData) { error in
                    if let error = error {
                        print("Error following interest: \(error.localizedDescription)")
                        return
                    }
                
                interestRef.updateData(["followerCount": FieldValue.increment(Int64(1))])
                followerCount += 1
                isFollowing.toggle()
                }
         
        }
    }
    
 
}
