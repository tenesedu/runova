import FirebaseFirestore
import FirebaseAuth

enum ConnectionStatus {
    case none
    case pending
    case connected
}

class ConnectionManager: ObservableObject {
    @Published var receivedRequests: [ConnectionRequest] = []
    @Published var sentRequests: [ConnectionRequest] = []
    @Published var connections: [String] = []
    
    private let db = Firestore.firestore()
    private let notificationManager = NotificationManager()
    
    func sendConnectionRequest(to userId: String) {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ No current user")
            return
        }

        // Create connection request
        let request = ConnectionRequest(
            senderId: currentUser.uid,
            receiverId: userId,
            status: "pending",
            createdAt: Date(),
            updatedAt: Date()
        )

        // Get a reference to the new document
        let requestDocumentRef = db.collection("connectionRequests").document()

        // Add request to Firestore using the reference
        requestDocumentRef.setData(request.toDictionary()) { [weak self] error in
            if let error = error {
                print("❌ Error sending connection request: \(error.localizedDescription)")
                return
            }

            print("✅ Connection request sent successfully with ID: \(requestDocumentRef.documentID)")

            // Fetch sender's name and profile image from Firestore
            self?.db.collection("users").document(currentUser.uid).getDocument { document, error in
                if let error = error {
                    print("❌ Error fetching sender's info: \(error.localizedDescription)")
                    return
                }

                guard let data = document?.data() else {
                    print("❌ Sender's data not found in Firestore")
                    return
                }

                let senderName = data["name"] as? String ?? "Unknown"
                let senderProfileUrl = data["profileImageUrl"] as? String ?? ""

                print("👤 Fetched sender's name: \(senderName), profileImageUrl: \(senderProfileUrl)")

                // Create request notification
                let notification = UserNotification(
                    type: .friendRequest,
                    senderId: currentUser.uid,
                    receiverId: userId,
                    senderName: senderName,
                    senderProfileUrl: senderProfileUrl,
                    relatedDocumentId: requestDocumentRef.documentID
                )

                // Add notification
                self?.notificationManager.createNotification(
                    notificationData: notification,
                    receiverId: userId
                )
            }
        }
    }

    func handleConnectionRequest(requestId: String, action: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No current user found")
            return
        }
        
        
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        
        
        // Update request status
        let requestRef = db.collection("connectionRequests").document(requestId)
        batch.updateData([
            "status": action,
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: requestRef)
        
        if action == "accepted" {
            // Fetch the request data to get the sender's ID
            db.collection("connectionRequests").document(requestId).getDocument { snapshot, error in
                if let error = error {
                    print("❌ Error fetching request data: \(error.localizedDescription)")
                    return
                }
                
                guard let requestData = snapshot?.data(),
                      let senderId = requestData["senderId"] as? String else {
                    print("❌ Invalid request data")
                    return
                }
                
                // Add to both users' friends arrays
                let currentUserRef = db.collection("users").document(currentUserId)
                let otherUserRef = db.collection("users").document(senderId)
                
                batch.updateData([
                    "friends": FieldValue.arrayUnion([senderId])
                ], forDocument: currentUserRef)
                
                batch.updateData([
                    "friends": FieldValue.arrayUnion([currentUserId])
                ], forDocument: otherUserRef)
                
                // Commit the batch
                batch.commit { error in
                    if let error = error {
                        print("❌ Error updating friends: \(error.localizedDescription)")
                        return
                    }
                    
                    print("✅ Friends updated successfully")
                    
                    // Fetch sender's name and profile image from Firestore
                    self.db.collection("users").document(currentUserId).getDocument { document, error in
                        if let error = error {
                            print("❌ Error fetching sender's info: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let data = document?.data() else {
                            print("❌ Sender's data not found in Firestore")
                            return
                        }
                        
                        let senderName = data["name"] as? String ?? "Unknown"
                        let senderProfileUrl = data["profileImageUrl"] as? String ?? ""
                        
                        
                        // Create a notification for the other user
                        let notification = UserNotification(
                            type: .friendAccepted,
                            senderId: currentUserId,
                            receiverId: senderId,
                            senderName: senderName,
                            senderProfileUrl: senderProfileUrl,
                            relatedDocumentId: requestId
                        )
                        
                        // Send the notification
                        self.notificationManager.createNotification(
                            notificationData: notification,
                            receiverId: senderId
                        )
                    }
                }
            }
        } else {
            // Commit the batch for non-acceptance actions (e.g., rejected)
            batch.commit { error in
                if let error = error {
                    print("❌ Error updating request status: \(error.localizedDescription)")
                } else {
                    print("✅ Request status updated to: \(action)")
                }
            }
        }
    }

    func checkConnectionStatus(with userId: String, completion: @escaping (ConnectionStatus) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.none)
            return
        }
        
        // First check if they're already friends
        db.collection("users").document(currentUserId).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let friends = data["friends"] as? [String],
               friends.contains(userId) {
                completion(.connected)
                return
            }
            
            // If not friends, check for pending requests
            self.db.collection("connectionRequests")
                .whereField("senderId", isEqualTo: currentUserId)
                .whereField("receiverId", isEqualTo: userId)
                .whereField("status", isEqualTo: "pending")
                .getDocuments { snapshot, error in
                    if let documents = snapshot?.documents, !documents.isEmpty {
                        completion(.pending)
                    } else {
                        completion(.none)
                    }
                }
        }
    }
    
    func fetchAllRequests() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Fetch received requests
        db.collection("connectionRequests")
            .whereField("receiverId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.receivedRequests = documents.map {
                    ConnectionRequest(id: $0.documentID, data: $0.data())
                }
            }
        
        // Fetch sent requests
        db.collection("connectionRequests")
            .whereField("senderId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.sentRequests = documents.map {
                    ConnectionRequest(id: $0.documentID, data: $0.data())
                }
            }
    }
    
    func cancelRequest(to userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("connectionRequests")
            .whereField("senderId", isEqualTo: currentUserId)
            .whereField("receiverId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, error in
                if let document = snapshot?.documents.first {
                    document.reference.updateData([
                        "status": "cancelled",
                        "updatedAt": FieldValue.serverTimestamp()
                    ])
                }
            }
    }
    
    func removeConnection(with userId: String) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let batch = db.batch()
        
        let currentUserRef = db.collection("users").document(currentUser.uid)
        let otherUserRef = db.collection("users").document(userId)
        
        batch.updateData([
            "friends": FieldValue.arrayRemove([userId])
        ], forDocument: currentUserRef)
        
        batch.updateData([
            "friends": FieldValue.arrayRemove([currentUser.uid])
        ], forDocument: otherUserRef)
        
        batch.commit { error in
            if let error = error {
                print("Error removing connection: \(error.localizedDescription)")
            }
        }
    }
}
    

