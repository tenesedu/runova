import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ConversationRow: View {
    let conversation: Conversation
    @Environment(\.colorScheme) var colorScheme
    @State private var participants: [Runner] = []
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile/Group Image
            if conversation.type == "direct" {
                UserProfileImage(url: conversation.otherUserProfile?.profileImageUrl)
            } else {
                GroupProfileImage(url: conversation.groupImageUrl)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Name
                Text(displayName)
                    .font(.headline)
                
                // Last message or participants for group
                Text(subText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeString(from: conversation.lastMessageTime))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                let unreadCount = conversation.unreadCount[Auth.auth().currentUser?.uid ?? ""] ?? 0
                if unreadCount > 0 {
                    Text("\(unreadCount)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .onAppear {
            if conversation.type == "group" {
                fetchParticipants()
            }
        }
    }
    
    private func fetchParticipants() {
        let db = Firestore.firestore()
        
        for participantId in conversation.participants {
            db.collection("users").document(participantId).getDocument { snapshot, error in
                if let userData = snapshot?.data() {
                    let user = UserApp(id: snapshot?.documentID ?? "", data: userData)
                    let runner = Runner(user: user)
                    DispatchQueue.main.async {
                        if !participants.contains(where: { $0.id == runner.id }) {
                            participants.append(runner)
                        }
                    }
                }
            }
        }
    }
    
    private var displayName: String {
        if conversation.type == "direct" {
            return conversation.otherUserProfile?.name ?? "Loading..."
        } else {
            return conversation.groupName ?? "Group"
        }
    }
    
    private var subText: String {
        if conversation.type == "direct" {
            return conversation.lastMessage.isEmpty ? "No messages yet" : conversation.lastMessage
        } else {
            // For group chats
            guard !conversation.lastMessage.isEmpty else {
                return "No messages yet"
            }
            
            let currentUserId = Auth.auth().currentUser?.uid
            
            // Check who sent the last message
            if let lastMessageSenderId = conversation.lastMessageSenderId {
                if lastMessageSenderId == currentUserId {
                    return "You: \(conversation.lastMessage)"
                } else {
                    // Find the sender name from participants
                    let senderName = participants.first { $0.id == lastMessageSenderId }?.name ?? "Unknown"
                    return "\(senderName): \(conversation.lastMessage)"
                }
            }
            
            return conversation.lastMessage
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

struct UserProfileImage: View {
    let url: String?
    
    var body: some View {
        AsyncImage(url: URL(string: url ?? "")) { image in
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
    }
}

struct GroupProfileImage: View {
    let url: String?
    
    var body: some View {
        AsyncImage(url: URL(string: url ?? "")) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
        } placeholder: {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(Text("👥"))
        }
    }
} 


struct ConversationRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview for direct message
            ConversationRow(conversation: mockDirectConversation)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Direct Message")
            
            // Preview for group message
            ConversationRow(conversation: mockGroupConversation)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Group Message")
        }
    }
}


// Mock data for direct message
let mockDirectConversation = Conversation(
    id: "123455",
    type: "direct",
    participants: ["123", "456"],
    createdAt: Date(),
    createdBy: "123",
    lastMessage: "Hey, how are you?",
    lastMessageTime: Date(),
    lastMessageSenderId: "123",
    unreadCount: ["456": 2],
    groupName: nil,
    groupImageUrl: nil,
    groupDescription: nil,
    adminId: nil,
    otherUserId: "123",
    otherUserProfile: UserProfile(
        id: "123",
        name: "Eduardo",
        profileImageUrl: "https://example.com/group.jpg"
    ),
    deletedFor: [:],
    deletedAt: [:]
)

// Mock data for group message
let mockGroupConversation = Conversation(
    id: "678910",
    type: "group",
    participants: ["123", "456", "789"],
    createdAt: Date(),
    createdBy: "123",
    lastMessage: "Let's meet at 7 AM!",
    lastMessageTime: Date(),
    lastMessageSenderId: "789",
    unreadCount: ["456": 1],
    groupName: "Running Club",
    groupImageUrl: "https://example.com/group.jpg",
    groupDescription: "A group for running enthusiasts",
    adminId: "123",
    otherUserId: nil,
    otherUserProfile: nil,
    deletedFor: [:],
    deletedAt: [:]
)
