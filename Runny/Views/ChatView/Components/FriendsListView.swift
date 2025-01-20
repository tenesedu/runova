import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FriendsListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var friends: [Runner] = []
    var onSelect: (Runner) -> Void
    
    var body: some View {
        NavigationView {
            List(friends) { friend in
                Button(action: { onSelect(friend) }) {
                    HStack {
                        AsyncImage(url: URL(string: friend.profileImageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(Text("👤"))
                        }
                        
                        Text(friend.name)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Select Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                fetchFriends()
            }
        }
    }
    
    private func fetchFriends() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(currentUserId).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let friendIds = data["friends"] as? [String] {
                
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
} 
