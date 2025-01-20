import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    private let db = Firestore.firestore()
    
    func createOrOpenDirectChat(with friend: Runner) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Check if conversation already exists
        db.collection("conversations")
            .whereField("type", isEqualTo: "direct")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { [weak self] snapshot, error in
                let existingChat = snapshot?.documents.first { document in
                    let data = document.data()
                    let participants = data["participants"] as? [String] ?? []
                    return participants.contains(friend.id)
                }
                
                if let existingChat = existingChat {
                    // Chat exists, do nothing as it will appear in the list
                    return
                }
                
                // Create new conversation
                let conversationData: [String: Any] = [
                    "type": "direct",
                    "participants": [currentUserId, friend.id],
                    "createdAt": FieldValue.serverTimestamp(),
                    "createdBy": currentUserId,
                    "lastMessage": "",
                    "lastMessageTime": FieldValue.serverTimestamp(),
                    "unreadCount": [:]
                ]
                
                self?.db.collection("conversations").addDocument(data: conversationData) { error in
                    if let error = error {
                        print("Error creating conversation: \(error.localizedDescription)")
                    }
                }
            }
    }
    
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
} 
