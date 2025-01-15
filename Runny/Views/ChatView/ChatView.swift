import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatView: View {
    @State private var conversations: [Conversation] = []
    @State private var searchText = ""
    @State private var showingNewGroupSheet = false
    @State private var groupName = ""
    @State private var selectedParticipants: Set<String> = []
    @Environment(\.colorScheme) var colorScheme

    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar at the top
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                
                // Content area
                ZStack {
                    if conversations.isEmpty {
                        VStack {
                            Spacer()
                                .frame(height: 50) // Adjust this value to fine-tune position
                            
                            EmptyStateView(
                                message: "No messages yet",
                                systemImage: "message.circle",
                                description: "Start a conversation with other runners!"
                            )
                            
                            Spacer()
                        }
                    } else {
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
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: ConnectionsView()) {
                        Image(systemName: "person.2")
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingNewGroupSheet = true }) {
                            Label("New Group", systemImage: "person.3")
                        }
                        
                        NavigationLink(destination: ConnectionsView()) {
                            Label("New Message", systemImage: "square.and.pencil")
                        }
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingNewGroupSheet) {
                CreateGroupView(
                    isPresented: $showingNewGroupSheet,
                    onComplete: { name, participants in
                        // The group is already created in Firestore by CreateGroupView
                        // We just need to refresh our conversations
                        fetchConversations()
                    }
                )
            }
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
            if conversation.type == "direct" {
                return conversation.otherUserProfile?.name.lowercased().contains(searchText.lowercased()) ?? false
            } else {
                return conversation.groupName?.lowercased().contains(searchText.lowercased()) ?? false
            }
        }
    }
    
    private func fetchConversations() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                
                let group = DispatchGroup()
                var updatedConversations: [Conversation] = []
                
                for document in documents {
                    let data = document.data()
                    guard let type = data["type"] as? String,
                          let participants = data["participants"] as? [String],
                          let createdAt = data["createdAt"] as? Timestamp,
                          let createdBy = data["createdBy"] as? String,
                          let lastMessage = data["lastMessage"] as? String,
                          let lastMessageTime = data["lastMessageTime"] as? Timestamp,
                          let unreadCount = data["unreadCount"] as? [String: Int] else {
                        continue
                    }
                    
                    var conversation = Conversation(
                        id: document.documentID,
                        type: type,
                        participants: participants,
                        createdAt: createdAt.dateValue(),
                        createdBy: createdBy,
                        lastMessage: lastMessage,
                        lastMessageTime: lastMessageTime.dateValue(),
                        unreadCount: unreadCount,
                        groupName: data["groupName"] as? String,
                        groupImageUrl: data["groupImageUrl"] as? String,
                        groupDescription: data["groupDescription"] as? String,
                        adminId: data["adminId"] as? String,
                        otherUserId: participants.first { $0 != userId }
                    )
                    
                    if type == "direct", let otherUserId = conversation.otherUserId {
                        group.enter()
                        db.collection("users").document(otherUserId).getDocument(source: .default) { snapshot, error in
                            defer { group.leave() }
                            
                            if let userData = snapshot?.data() {
                                let user = User(id: snapshot?.documentID ?? "", data: userData)
                                conversation.otherUserProfile = Runner(user: user)
                                updatedConversations.append(conversation)
                            }
                        }
                    } else {
                        updatedConversations.append(conversation)
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
            // Profile/Group Image
            Group {
                if conversation.type == "direct" {
                    // Direct message profile image
                    if let profileUrl = conversation.otherUserProfile?.profileImageUrl,
                       !profileUrl.isEmpty {
                        AsyncImage(url: URL(string: profileUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Circle()
                            .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            .overlay(Text("👤"))
                    }
                } else {
                    // Group image
                    if let groupImageUrl = conversation.groupImageUrl,
                       !groupImageUrl.isEmpty {
                        AsyncImage(url: URL(string: groupImageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Circle()
                            .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            .overlay(
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            // Message Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if conversation.type == "direct" {
                        Text(conversation.otherUserProfile?.name ?? "Loading...")
                            .font(.system(size: 16, weight: .semibold))
                    } else {
                        Text(conversation.groupName ?? "Group Chat")
                            .font(.system(size: 16, weight: .semibold))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text(timeString(from: conversation.lastMessageTime))
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                HStack(alignment: .top) {
                    if conversation.type == "group" {
                        Text("\(conversation.participants.count) members • ")
                            .font(.system(size: 13))
                            .foregroundColor(.gray) +
                        Text(conversation.lastMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    } else {
                        Text(conversation.lastMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    let unreadCount = conversation.unreadCount[Auth.auth().currentUser?.uid ?? ""] ?? 0
                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(minWidth: 18)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
                .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
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
