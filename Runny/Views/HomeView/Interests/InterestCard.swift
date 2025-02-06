import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct InterestCard: View {
    let interest: Interest
    @State private var isFollowing: Bool
    @State private var followersCount: Int
    let cardWidth: CGFloat = 280
    let cardHeight: CGFloat = 180
    
    init(interest: Interest) {
        self.interest = interest
        self._isFollowing = State(initialValue: interest.isFollowed)
        self._followersCount = State(initialValue: interest.followersCount)
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
                    Text(String(format: NSLocalizedString("%d followers", comment: ""), followersCount))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Follow Button
                Button(action: {
                    toggleFollow()
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
        db.collection("interests").document(interest.id)
            .collection("followers").document(userId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Error checking follow status: \(error.localizedDescription)")
                    return
                }
                isFollowing = snapshot?.exists ?? false
            }
    }
    
    private func toggleFollow() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let interestRef = db.collection("interests").document(interest.id)
        let followerRef = interestRef.collection("followers").document(userId)
        
        // Optimistically update UI
        isFollowing.toggle()
        followersCount += isFollowing ? 1 : -1
        
        if isFollowing {
            // Follow
            let followerData: [String: Any] = [
                "userId": userId,
                "followedAt": FieldValue.serverTimestamp(),
                "role": "member"
            ]
            
            followerRef.setData(followerData) { error in
                if let error = error {
                    print("Error following interest: \(error.localizedDescription)")
                    isFollowing.toggle()
                    followersCount -= 1
                    return
                }
                
                interestRef.updateData([
                    "followersCount": FieldValue.increment(Int64(1))
                ])
                
                // Notify parent views to update their arrays
                NotificationCenter.default.post(
                    name: NSNotification.Name("InterestFollowStatusChanged"),
                    object: nil,
                    userInfo: ["interest": self.interest, "isFollowing": true]
                )
            }
        } else {
            // Unfollow
            followerRef.delete { error in
                if let error = error {
                    print("Error unfollowing interest: \(error.localizedDescription)")
                    isFollowing.toggle()
                    followersCount += 1
                    return
                }
                
                interestRef.updateData([
                    "followersCount": FieldValue.increment(Int64(-1))
                ])
                
                // Notify parent views to update their arrays
                NotificationCenter.default.post(
                    name: NSNotification.Name("InterestFollowStatusChanged"),
                    object: nil,
                    userInfo: ["interest": self.interest, "isFollowing": false]
                )
            }
        }
    }
}
