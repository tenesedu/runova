import SwiftUI
import FirebaseFirestore
import FirebaseAuth


struct ConnectionsView: View {
    @State private var selectedTab: Int
    @State private var friends: [Runner] = []
    @StateObject private var connectionManager = ConnectionManager()
    
    init(selectedTab: Int = 0){
        _selectedTab = State(initialValue: selectedTab)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector at the top
            Picker("", selection: $selectedTab) {
                Text("Friends").tag(0)
                Text("Requests").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if selectedTab == 0 {
                // Friends List
                if friends.isEmpty {
                    EmptyStateView(
                        message: "No Friends Yet",
                        systemImage: "person.2",
                        description: "Connect with other runners to see them here!"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(friends) { friend in
                                NavigationLink(destination: RunnerDetailView(runner: friend)) {
                                    FriendRow(friend: friend)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            } else {
                // Requests List
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if !connectionManager.receivedRequests.isEmpty {
                            Text("Received Requests")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(connectionManager.receivedRequests) { request in
                                PendingRequestRow(request: request)
                                    .padding(.horizontal)
                            }
                        }
                        
                        if !connectionManager.sentRequests.isEmpty {
                            Text("Sent Requests")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, 16)
                            
                            ForEach(connectionManager.sentRequests) { request in
                                SentRequestRow(request: request)
                                    .padding(.horizontal)
                            }
                        }
                        
                        if connectionManager.receivedRequests.isEmpty && connectionManager.sentRequests.isEmpty {
                            EmptyStateView(
                                message: "No Pending Requests",
                                systemImage: "person.badge.plus",
                                description: "You don't have any connection requests at the moment."
                            )
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Connections")
        .onAppear {
            fetchFriends()
            connectionManager.fetchAllRequests()
        }
    }
    
    private func fetchFriends() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(currentUserId).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let friendIds = data["friends"] as? [String] else { return }
            
            friends.removeAll()
            
            for friendId in friendIds {
                db.collection("users").document(friendId).getDocument { snapshot, error in
                    if let userData = snapshot?.data() {
                        let user = UserApp(id: snapshot?.documentID ?? "", data: userData)
                        let friend = Runner(user: user)
                        DispatchQueue.main.async {
                            if !friends.contains(where: { $0.id == friend.id }) {
                                friends.append(friend)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct FriendRow: View {
    let friend: Runner
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: friend.profileImageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(Text("👤"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.headline)
                Text(friend.city)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
} 
