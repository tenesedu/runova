import SwiftUI
import FirebaseAuth
import FirebaseFirestore


struct ChatDetailView: View {
    let conversation: Conversation
    let allowsDismiss: Bool
    
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    @State private var isLoading = false
    @State private var showingGroupInfo = false
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var participants: [Runner] = []
    @State private var shouldDismiss = false
    @State private var pendingMessages: Set<String> = []
    
    var body: some View {
        VStack(spacing: 0) {
            if allowsDismiss {
                // Header with back button
                ChatHeaderView(
                    conversation: conversation,
                    participants: participants,
                    onBackTap: { 
                        shouldDismiss = true
                        dismiss()
                    },
                    onInfoTap: { showingGroupInfo = true }
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
            }
            
            // Messages
            MessagesView(
                messages: messages,
                isGroupChat: conversation.type == "group"
            )
            
            // Input
            MessageInputField(text: $newMessage, onSend: sendMessage)
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingGroupInfo) {
            if conversation.type == "group" {
                GroupInfoView(conversation: conversation, participants: participants)
            }
        }
        .onAppear {
            fetchMessages()
            markConversationAsRead()
            if conversation.type == "group" {
                fetchParticipants()
            }
        }
        .interactiveDismissDisabled(!shouldDismiss)
    }
    
    private func fetchMessages() {
        let db = Firestore.firestore()
        db.collection("conversations")
            .document(conversation.id)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                
                // Only get messages from Firestore, ignore pending ones
                let fetchedMessages = documents.map { Message(id: $0.documentID, data: $0.data()) }
                
                // Only update if there are actual changes
                if Set(fetchedMessages.map { $0.id }) != Set(messages.map { $0.id }) {
                    messages = fetchedMessages
                }
            }
    }

    
    private func sendMessage() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let messageContent = newMessage
        let tempMessageId = UUID().uuidString
        newMessage = ""
        
        let db = Firestore.firestore()
        
        // Create temporary message
        let tempMessage = Message(
            id: tempMessageId,
            conversationId: conversation.id,
            senderId: currentUserId,
            content: messageContent,
            timestamp: Date(),
            senderName: "Sending...",
            senderProfileUrl: ""
        )
        
        // Don't add temporary message to UI, let the listener handle it
        Task {
            do {
                let userDoc = try await db.collection("users").document(currentUserId).getDocument()
                guard let userData = userDoc.data(),
                      let userName = userData["name"] as? String else { throw NSError() }
                
                let messageData: [String: Any] = [
                    "conversationId": conversation.id,
                    "senderId": currentUserId,
                    "content": messageContent,
                    "timestamp": FieldValue.serverTimestamp(),
                    "senderName": userName,
                    "senderProfileUrl": userData["profileImageUrl"] as? String ?? ""
                ]
                
                try await db.collection("conversations")
                    .document(conversation.id)
                    .collection("messages")
                    .addDocument(data: messageData)
                
                var updateData: [String: Any] = [
                    "lastMessage": messageContent,
                    "lastMessageTime": FieldValue.serverTimestamp(),
                    "lastMessageSenderId": currentUserId
                ]
                
                for participantId in conversation.participants where participantId != currentUserId {
                    updateData["unreadCount.\(participantId)"] = FieldValue.increment(Int64(1))
                }
                
                try await db.collection("conversations")
                    .document(conversation.id)
                    .updateData(updateData)
                
            } catch {
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }

    
    private func markConversationAsRead() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("conversations").document(conversation.id).updateData([
            "unreadCount.\(currentUserId)": 0
        ])
    }
    
    private func fetchParticipants() {
        guard conversation.type == "group" else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        let dispatchGroup = DispatchGroup()
        
        for participantId in conversation.participants {
            dispatchGroup.enter()
            db.collection("users").document(participantId).getDocument { snapshot, error in
                defer { dispatchGroup.leave() }
                
                if let document = snapshot,
                   let data = document.data() {
                    let user = UserApp(id: document.documentID, data: data)
                    let runner = Runner(user: user)
                    DispatchQueue.main.async {
                        if !participants.contains(where: { $0.id == runner.id }) {
                            participants.append(runner)
                        }
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            participants.sort { $0.name < $1.name }
        }
    }
}

struct MessagesView: View {
    let messages: [Message]
    let isGroupChat: Bool
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(
                            message: message,
                            isFromCurrentUser: message.senderId == Auth.auth().currentUser?.uid,
                            showSenderName: isGroupChat
                        )
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
    }
}

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    let showSenderName: Bool // Add this to conditionally show the sender's name
    
    var body: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
            // Show sender's name if it's a group chat and the message is from another user
            if showSenderName && !isFromCurrentUser {
                Text(message.senderName)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 8) // Adjust padding to align with the message bubble
            }
            
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
}

// Update GroupInfoView to accept participants
struct GroupInfoView: View {
    let conversation: Conversation
    let participants: [Runner]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    // Group Image and Name
                    HStack {
                        Spacer()
                        VStack {
                            AsyncImage(url: URL(string: conversation.groupImageUrl ?? "")) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                    .overlay(Image(systemName: "person.3.fill"))
                            }
                            
                            Text(conversation.groupName ?? "Group Chat")
                                .font(.title2)
                                .bold()
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    if let description = conversation.groupDescription {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("Participants (\(participants.count))")) {
                    ForEach(participants) { participant in
                        ParticipantRow(participant: participant)
                    }
                }
            }
            .navigationTitle("Group Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        print("Back button tapped")
                        dismiss()
                    }
                }
            }
        }
    }
}
