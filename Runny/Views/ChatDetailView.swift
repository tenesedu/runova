import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatDetailView: View {
    let conversation: Conversation
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    @State private var isLoading = false
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var shouldScrollToBottom = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message, isFromCurrentUser: message.senderId == Auth.auth().currentUser?.uid)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { [oldCount = messages.count] newCount in
                    if newCount > oldCount {
                        withAnimation {
                            if let lastId = messages.last?.id {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                .onAppear {
                    if let lastId = messages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            
            // Message Input
            HStack(spacing: 12) {
                TextField("Type a message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        if !newMessage.isEmpty {
                            sendMessage()
                        }
                    }
                
                Button(action: {
                    isFocused = false  // Dismiss keyboard before sending
                    sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(newMessage.isEmpty ? Color.gray : Color.blue)
                        .clipShape(Circle())
                }
                .disabled(newMessage.isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: -5)
        }
        .navigationTitle(conversation.otherUserProfile?.name ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchMessages()
            markConversationAsRead()
        }
        .onDisappear {
            isFocused = false  // Dismiss keyboard when leaving the view
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    isFocused = false  // Dismiss keyboard before going back
                    dismiss()
                }
            }
        }
    }
    
    private func fetchMessages() {
        guard (Auth.auth().currentUser?.uid) != nil else { return }
        
        let db = Firestore.firestore()
        db.collection("messages")
            .whereField("conversationId", isEqualTo: conversation.id)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                messages = documents.map { Message(id: $0.documentID, data: $0.data()) }
            }
    }
    
    private func sendMessage() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let db = Firestore.firestore()
        let messageData: [String: Any] = [
            "conversationId": conversation.id,
            "senderId": currentUserId,
            "receiverId": conversation.otherUserId,
            "content": newMessage,
            "timestamp": FieldValue.serverTimestamp(),
            "senderName": Auth.auth().currentUser?.displayName ?? "Unknown",
            "senderProfileUrl": Auth.auth().currentUser?.photoURL?.absoluteString ?? ""
        ]
        
        // Add message
        db.collection("messages").addDocument(data: messageData)
        
        // Update conversation
        db.collection("conversations").document(conversation.id).updateData([
            "lastMessage": newMessage,
            "lastMessageTime": FieldValue.serverTimestamp(),
            "unreadCount.\(conversation.otherUserId)": FieldValue.increment(Int64(1))
        ])
        
        newMessage = ""
    }
    
    private func markConversationAsRead() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("conversations").document(conversation.id).updateData([
            "unreadCount.\(currentUserId)": 0
        ])
    }
}

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(isFromCurrentUser ? Color.blue : Color(.systemGray6))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !isFromCurrentUser { Spacer() }
        }
    }
} 
