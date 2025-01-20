import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var selectedConversation: Conversation?
    @Published var showChatDetail = false
    
    private let db = Firestore.firestore()
    
    // MARK: - Fetch Conversations
    func fetchConversations() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        print("Fetching conversations for user: \(currentUserId)")
        
        db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching conversations: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                print("Found \(documents.count) conversations")
                
                let group = DispatchGroup()
                var newConversations: [Conversation] = []
                
                for document in documents {
                    let data = document.data()
                    print("Processing conversation: \(document.documentID)")
                    print("Conversation data: \(data)")
                    
                    guard let type = data["type"] as? String,
                          let participants = data["participants"] as? [String],
                          let createdAt = data["createdAt"] as? Timestamp,
                          let createdBy = data["createdBy"] as? String else {
                        continue
                    }
                    
                    // For group chats, also verify group-specific fields
                    if type == "group" {
                        guard let name = data["name"] as? String else {
                            print("Missing name for group conversation: \(document.documentID)")
                            continue
                        }
                    }
                    
                    group.enter()
                    
                    var conversation = Conversation(
                        id: document.documentID,
                        type: type,
                        participants: participants,
                        createdAt: createdAt.dateValue(),
                        createdBy: createdBy,
                        lastMessage: data["lastMessage"] as? String ?? "",
                        lastMessageTime: (data["lastMessageTime"] as? Timestamp)?.dateValue() ?? Date(),
                        lastMessageSenderId: data["lastMessageSenderId"] as? String,
                        unreadCount: data["unreadCount"] as? [String: Int] ?? [:],
                        groupName: data["name"] as? String,
                        groupImageUrl: data["imageUrl"] as? String,
                        groupDescription: data["description"] as? String,
                        adminId: data["adminId"] as? String,
                        otherUserId: type == "direct" ? participants.first { $0 != currentUserId } : nil
                    )
                    
                    print("Created conversation object: type=\(type), groupName=\(conversation.groupName ?? "nil")")
                    
                    if type == "direct" {
                        if let otherUserId = conversation.otherUserId {
                            self?.db.collection("users").document(otherUserId).getDocument { snapshot, error in
                                if let userData = snapshot?.data() {
                                    let user = UserApp(id: snapshot?.documentID ?? "", data: userData)
                                    conversation.otherUserProfile = Runner(user: user)
                                }
                                newConversations.append(conversation)
                                group.leave()
                            }
                        } else {
                            group.leave()
                        }
                    } else {
                        // For group chats
                        DispatchQueue.main.async {
                            print("Adding group conversation: \(conversation.groupName ?? "unnamed")")
                            newConversations.append(conversation)
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    let sortedConversations = newConversations.sorted {
                        $0.lastMessageTime > $1.lastMessageTime
                    }
                    print("Final conversations count: \(sortedConversations.count)")
                    print("Groups: \(sortedConversations.filter { $0.type == "group" }.count)")
                    print("Direct: \(sortedConversations.filter { $0.type == "direct" }.count)")
                    self?.conversations = sortedConversations
                }
            }
    }
    
    // MARK: - Create or Open Direct Chat
    func createOrOpenDirectChat(with friend: Runner, completion: @escaping (Conversation?) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        
        let db = Firestore.firestore()
        
        // Check if conversation already exists
        db.collection("conversations")
            .whereField("type", isEqualTo: "direct")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching conversations: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                if let documents = snapshot?.documents {
                    // Look for existing direct conversation with this runner
                    let existingConversation = documents.first { document in
                        let data = document.data()
                        let participants = data["participants"] as? [String] ?? []
                        return participants.count == 2 &&
                               participants.contains(friend.id)
                    }
                    
                    if let existing = existingConversation {
                        // Use existing conversation
                        let data = existing.data()
                        var conversation = Conversation(
                            id: existing.documentID,
                            type: "direct",
                            participants: data["participants"] as? [String] ?? [],
                            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                            createdBy: data["createdBy"] as? String ?? "",
                            lastMessage: data["lastMessage"] as? String ?? "",
                            lastMessageTime: (data["lastMessageTime"] as? Timestamp)?.dateValue() ?? Date(),
                            lastMessageSenderId: data["lastMessageSenderId"] as? String ?? "",
                            unreadCount: data["unreadCount"] as? [String: Int] ?? [:],
                            groupName: nil,
                            groupImageUrl: nil,
                            groupDescription: nil,
                            adminId: nil,
                            otherUserId: friend.id,
                            deletedFor: data["deletedFor"] as? [String: Bool] ?? [:],
                            deletedAt: (data["deletedAt"] as? [String: Timestamp] ?? [:]).mapValues { $0.dateValue() }
                        )
                        conversation.otherUserProfile = friend
                        completion(conversation)
                    } else {
                        // Create new conversation
                        self.createNewConversation(currentUserId: currentUserId, friend: friend, completion: completion)
                    }
                }
            }
    }
    
    // MARK: - Create New Conversation
    private func createNewConversation(currentUserId: String, friend: Runner, completion: @escaping (Conversation?) -> Void) {
        let db = Firestore.firestore()
        let newConversationRef = db.collection("conversations").document()
        let participants = [currentUserId, friend.id]
        
        let conversationData: [String: Any] = [
            "type": "direct",
            "participants": participants,
            "createdAt": FieldValue.serverTimestamp(),
            "createdBy": currentUserId,
            "lastMessage": "",
            "lastMessageTime": FieldValue.serverTimestamp(),
            "unreadCount": participants.reduce(into: [String: Int]()) { dict, id in
                dict[id] = 0
            }
        ]
        
        // Create batch
        let batch = db.batch()
        
        // Set the conversation data
        batch.setData(conversationData, forDocument: newConversationRef)
        
        // Update both users' conversation arrays
        for userId in participants {
            let userRef = db.collection("users").document(userId)
            batch.updateData([
                "conversations": FieldValue.arrayUnion([newConversationRef.documentID])
            ], forDocument: userRef)
        }
        
        // Commit the batch once
        batch.commit { error in
            if let error = error {
                print("Error creating conversation: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            var conversation = Conversation(
                id: newConversationRef.documentID,
                type: "direct",
                participants: participants,
                createdAt: Date(),
                createdBy: currentUserId,
                lastMessage: "",
                lastMessageTime: Date(),
                lastMessageSenderId: currentUserId,
                unreadCount: participants.reduce(into: [String: Int]()) { dict, id in
                    dict[id] = 0
                },
                groupName: nil,
                groupImageUrl: nil,
                groupDescription: nil,
                adminId: nil,
                otherUserId: friend.id
            )
            conversation.otherUserProfile = friend
            completion(conversation)
        }
    }
}
