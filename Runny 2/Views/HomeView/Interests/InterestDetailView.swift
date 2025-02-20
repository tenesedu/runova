import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct InterestDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let interest: Interest
    @State private var posts: [Post] = []
    @Binding var isFollowing: Bool
    @Binding var followerCount: Int
    @State private var showingCreatePost = false
    @State private var selectedPost: Post?
    
    private let headerHeight: CGFloat = 250
    
    var body: some View {
       
        ScrollView {
            VStack(spacing: 0) {
                // Header Section with Custom Back Button
                ZStack(alignment: .top) {
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
                        colors: [.black.opacity(0.4), .clear, .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Custom Back Button
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    .padding(.top, 50)
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Interest Info
                    VStack(spacing: 16) {
                        Spacer()
                        
                        // Title and Follow Button Row
                        HStack(alignment: .center, spacing: 16) {
                            // Icon and Title
                            HStack(spacing: 10) {
                                Image(systemName: interest.iconName)
                                    .font(.title2)
                                    .foregroundColor(interest.color)
                                    .padding(8)
                                    .background(Circle().fill(Color.white))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(interest.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("\(followerCount) followers")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                }
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
                        
                        // Description
                        if !interest.description.isEmpty {
                            Text(interest.description)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                
                
                Button(action: { showingCreatePost = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.pencil")
                        Text(NSLocalizedString("Create Post", comment: ""))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(interest.color)
                            .shadow(color: interest.color.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .padding()
                
                // Posts Section with enhanced design
                VStack(alignment: .leading, spacing: 20) {
                    Text(NSLocalizedString("Recent Posts", comment: ""))
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if posts.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text(NSLocalizedString("No posts yet", comment: ""))
                                .font(.headline)
                            
                            Text(String(format: NSLocalizedString("Be the first to post about %@", comment :"") , interest.name))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 16) {
                                                
                            ForEach(posts) { post in
                                Button(action: {
                                    selectedPost = post
                                }) {
                                    PostView(post: post)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .refreshable {
            // Refresh all content
            await refreshContent()
        }
        .sheet(isPresented: $showingCreatePost) {
            NewInterestPostView(interest: interest)
        }
        .onAppear {
            checkFollowStatus()
            fetchPosts()
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
               
                }
         
        }
    }
    
    
    private func fetchPosts() {
        let db = Firestore.firestore()
        db.collection("posts")
            .whereField("interestId", isEqualTo: interest.id)
            .order(by: "createdAt", descending: true)
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
