import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatView: View {
    @State private var conversations: [Conversation] = []
    @State private var searchText = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                
                if conversations.isEmpty {
                    EmptyStateView(
                        message: "No messages yet",
                        systemImage: "message.circle",
                        description: "Start a conversation with other runners!"
                    )
                } else {
                    // Conversations list
                    List {
                        ForEach(filteredConversations) { conversation in
                            NavigationLink(destination: ChatDetailView(conversation: conversation)) {
                                ConversationRow(conversation: conversation)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteConversation(conversation)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Messages")
            .onAppear {
                fetchConversations()
            }
        }
    }
    
    private func deleteConversation(_ conversation: Conversation) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Delete the conversation document
        db.collection("conversations").document(conversation.id).delete { error in
            if let error = error {
                print("Error deleting conversation: \(error.localizedDescription)")
                return
            }
            
            // Delete all messages in the conversation
            db.collection("messages")
                .whereField("conversationId", isEqualTo: conversation.id)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error fetching messages: \(error.localizedDescription)")
                        return
                    }
                    
                    let batch = db.batch()
                    snapshot?.documents.forEach { doc in
                        batch.deleteDocument(doc.reference)
                    }
                    
                    batch.commit { error in
                        if let error = error {
                            print("Error deleting messages: \(error.localizedDescription)")
                        }
                    }
                }
            
            // Remove conversation from local state
            if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
                conversations.remove(at: index)
            }
        }
    }
    
    // Add filtered conversations based on search text
    private var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return conversations
        }
        return conversations.filter { conversation in
            conversation.otherUserProfile?.name.lowercased().contains(searchText.lowercased()) ?? false
        }
    }
    
    private func fetchConversations() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        // Use snapshot listener to get real-time updates
        db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                
                // Create a dispatch group to handle async user profile fetching
                let group = DispatchGroup()
                var updatedConversations: [Conversation] = []
                
                for document in documents {
                    let data = document.data()
                    let participants = data["participants"] as? [String] ?? []
                    let otherUserId = participants.first { $0 != userId } ?? ""
                    
                    let conversation = Conversation(
                        id: document.documentID,
                        otherUserId: otherUserId,
                        lastMessage: data["lastMessage"] as? String ?? "",
                        lastMessageTime: (data["lastMessageTime"] as? Timestamp)?.dateValue() ?? Date(),
                        unreadCount: data["unreadCount.\(userId)"] as? Int ?? 0
                    )
                    
                    group.enter()
                    // Fetch other user's profile
                    db.collection("users").document(otherUserId).getDocument { snapshot, error in
                        defer { group.leave() }
                        
                        if let userData = snapshot?.data() {
                            var updatedConversation = conversation
                            updatedConversation.otherUserProfile = UserProfile(
                                id: snapshot?.documentID ?? "",
                                name: userData["name"] as? String ?? "Unknown",
                                age: userData["age"] as? String ?? "",
                                averagePace: userData["averagePace"] as? String ?? "",
                                city: userData["city"] as? String ?? "",
                                profileImageUrl: userData["profileImageUrl"] as? String ?? "",
                                gender: userData["gender"] as? String ?? ""
                            )
                            updatedConversations.append(updatedConversation)
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    self.conversations = updatedConversations.sorted { $0.lastMessageTime > $1.lastMessageTime }
                }
            }
    }
}

struct SearchBar: View {
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16))
            
            TextField("Search messages", text: $text)
                .font(.system(size: 16))
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
        )
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let profileUrl = conversation.otherUserProfile?.profileImageUrl,
               !profileUrl.isEmpty {
                AsyncImage(url: URL(string: profileUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            } else {
                Circle()
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    .frame(width: 52, height: 52)
                    .overlay(Text("👤"))
            }
            
            // Message Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUserProfile?.name ?? "Loading...")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(timeString(from: conversation.lastMessageTime))
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                HStack(alignment: .top) {
                    Text(conversation.lastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(minWidth: 18)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    private func timeString(from date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yy"
            return formatter.string(from: date)
        }
    }
}

struct Conversation: Identifiable {
    let id: String
    let otherUserId: String
    let lastMessage: String
    let lastMessageTime: Date
    let unreadCount: Int
    var otherUserProfile: UserProfile?
} 
