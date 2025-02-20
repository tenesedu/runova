import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FeedView: View {
    @State private var posts: [Post] = []
    @State private var showingNewPost = false
    @State private var selectedInterest: String?
    @State private var interests: [Interest] = []
    @State private var searchText = ""
    
    var filteredPosts: [Post] {
        let interestFiltered = selectedInterest == nil ? posts : posts.filter { $0.interestName == selectedInterest }
        
        if searchText.isEmpty {
            return interestFiltered
        }
        return interestFiltered.filter { post in
            post.content.localizedCaseInsensitiveContains(searchText) ||
            post.creatorName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField(NSLocalizedString("Search posts...", comment: "Search bar placeholder"), text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    
                    // Interests Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // All Filter Button
                            Button(action: {
                                selectedInterest = nil // Reset to show all posts
                            }) {
                                Text("All")
                                    .padding()
                                    .background(selectedInterest == nil ? Color.black : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedInterest == nil ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            
                            ForEach(interests) { interest in
                                InterestFilterButton(
                                    interest: interest,
                                    isSelected: selectedInterest == interest.name
                                ) {
                                    if selectedInterest == interest.name {
                                        selectedInterest = nil
                                    } else {
                                        selectedInterest = interest.name
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Posts List
                    if filteredPosts.isEmpty {
                        EmptyStateView(
                            message: searchText.isEmpty ? "No posts yet" : "No results found",
                            systemImage: "text.bubble",
                            description: searchText.isEmpty ? "Be the first to share something!" : "Try adjusting your search"
                        )
                    } else {
                        ForEach(filteredPosts) { post in
                            PostCard(post: post)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewPost = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingNewPost) {
                NewPostView(interests: interests)
            }
            .refreshable {
                // Call your fetch function here to refresh the posts
                fetchPosts()
            }
        }
        .onAppear {
            fetchPosts()
            fetchInterests()
        }
    }
    
    private func fetchPosts() {
        let db = Firestore.firestore()
        db.collection("posts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching posts: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                posts = documents.map { Post(id: $0.documentID, data: $0.data()) }
            }
    }
    
    private func fetchInterests() {
        let db = Firestore.firestore()
        db.collection("interests")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching interests: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                interests = documents.map { Interest(id: $0.documentID, data: $0.data()) }
            }
    }
}

// Interest Filter Button
struct InterestFilterButton: View {
    let interest: Interest
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(interest.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? interest.color.opacity(0.2) : Color(.systemGray6))
                .foregroundColor(isSelected ? interest.color : .primary)
                .clipShape(Capsule())
        }
    }
}

// Post Card View
struct PostCard: View {
    let post: Post
    @State private var isLiked = false
    @State private var likesCount: Int
    @State private var showingDetail = false
    @State private var showingComments = false
    
    init(post: Post) {
        self.post = post
        self._likesCount = State(initialValue: post.likesCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Info
            HStack {
                AsyncImage(url: URL(string: post.creatorImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(post.creatorName)
                        .font(.headline)
                    Text(post.interestName)
                        .font(.caption)
                        .foregroundColor(Color(.systemGray4))
                }
                
                Spacer()
                
                Text(timeAgo(from: post.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
           
            // Content
            Text(post.content)
                .font(.body)
                .lineLimit(3)
            
            // Interaction Buttons
            HStack(spacing: 20) {
                // Like Button
                HStack(spacing: 4) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .gray)
                        .onTapGesture {
                            handleLike()
                        }
                    Text("\(likesCount)")
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Comment Button
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.gray)
                        .onTapGesture {
                            showingComments = true
                        }
                    Text("\(post.commentsCount)")
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            //PostDetailView(post: post)
        }
        .sheet(isPresented: $showingComments) {
            CommentsView(post: post)
        }
        .onAppear {
            checkIfLiked()
        }
    }
    
    private func checkIfLiked() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("posts").document(post.id)
            .collection("likes").document(userId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Error checking like status: \(error.localizedDescription)")
                    return
                }
                isLiked = snapshot?.exists ?? false
            }
    }
    
    private func handleLike() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        print("Like button tapped") // Debug print
        
        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(post.id)
        let likeRef = postRef.collection("likes").document(userId)
        
        // Optimistically update UI
        isLiked.toggle()
        likesCount += isLiked ? 1 : -1
        
        if isLiked {
            // Add like
            likeRef.setData(["timestamp": FieldValue.serverTimestamp()]) { error in
                if let error = error {
                    print("Error adding like: \(error.localizedDescription)")
                    // Revert UI if error occurs
                    isLiked.toggle()
                    likesCount -= 1
                    return
                }
                
                // Update post likes count
                postRef.updateData([
                    "likes": FieldValue.increment(Int64(1))
                ])
            }
        } else {
            // Remove like
            likeRef.delete { error in
                if let error = error {
                    print("Error removing like: \(error.localizedDescription)")
                    // Revert UI if error occurs
                    isLiked.toggle()
                    likesCount += 1
                    return
                }
                
                // Update post likes count
                postRef.updateData([
                    "likes": FieldValue.increment(Int64(-1))
                ])
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
