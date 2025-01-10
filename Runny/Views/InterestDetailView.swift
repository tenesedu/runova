import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct InterestDetailView: View {
    let interest: Interest
    @State private var posts: [Post] = []
    @State private var isFollowing: Bool
    @State private var followersCount: Int
    @State private var showingCreatePost = false
    
    private let headerHeight: CGFloat = 200
    
    init(interest: Interest) {
        self.interest = interest
        self._isFollowing = State(initialValue: interest.isFollowed)
        self._followersCount = State(initialValue: interest.followersCount)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Section
                ZStack(alignment: .bottom) {
                    // Background Image
                    AsyncImage(url: URL(string: interest.backgroundImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray
                    }
                    .frame(height: headerHeight)
                    .clipped()
                    
                    // Gradient Overlay
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Interest Info
                    VStack(spacing: 12) {
                        // Title Row
                        HStack(alignment: .center, spacing: 16) {
                            // Icon and Title
                            HStack(spacing: 10) {
                                Image(systemName: interest.iconName)
                                    .font(.title3)
                                    .foregroundColor(interest.color)
                                
                                Text(interest.name)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // Follow Button
                            Button(action: toggleFollow) {
                                Text(isFollowing ? "Following" : "Follow")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(isFollowing ? interest.color.opacity(0.2) : interest.color)
                                    .foregroundColor(isFollowing ? interest.color : .white)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        // Followers Count
                        HStack {
                            Text("\(followersCount) followers")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                
                // Create Post Button
                Button(action: {
                    showingCreatePost = true
                }) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("Create Post")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(interest.color)
                    .cornerRadius(12)
                }
                .padding()
                .shadow(color: interest.color.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Feed Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Recent Posts")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if posts.isEmpty {
                        VStack(spacing: 12) {
                            Text("No posts yet")
                                .font(.headline)
                            Text("Be the first to post about \(interest.name)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(posts) { post in
                                PostCard(post: post)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            // Refresh all content
            await refreshContent()
        }
        .sheet(isPresented: $showingCreatePost) {
            NavigationView {
                NewPostView(interests: [interest], selectedInterest: interest)
            }
        }
        .onAppear {
            checkFollowStatus()
            fetchPosts()
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
            followerRef.setData(["timestamp": FieldValue.serverTimestamp()]) { error in
                if let error = error {
                    print("Error following interest: \(error.localizedDescription)")
                    isFollowing.toggle()
                    followersCount -= 1
                    return
                }
                
                interestRef.updateData([
                    "followersCount": FieldValue.increment(Int64(1))
                ])
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
            }
        }
    }
    
    private func fetchPosts() {
        let db = Firestore.firestore()
        db.collection("posts")
            .whereField("interest", isEqualTo: interest.name)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching posts: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                posts = documents.map { Post(id: $0.documentID, data: $0.data()) }
            }
    }
    
    private func refreshContent() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await withCheckedContinuation { continuation in
                    checkFollowStatus()
                    continuation.resume()
                }
            }
            
            group.addTask {
                await withCheckedContinuation { continuation in
                    fetchPosts()
                    continuation.resume()
                }
            }
        }
    }
} 
