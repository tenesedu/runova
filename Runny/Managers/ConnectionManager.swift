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
    
    func sendConnectionRequest(to userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let request = [
            "fromUserId": currentUserId,
            "toUserId": userId,
            "status": "pending",
            "timestamp": FieldValue.serverTimestamp()
        ] as [String : Any]
        
        db.collection("connectionRequests").addDocument(data: request)
    }
    
    func acceptConnectionRequest(requestId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // First get the request to get the sender ID
        db.collection("connectionRequests").document(requestId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let senderId = data["senderId"] as? String else { return }
            
            let batch = self.db.batch()
            
            // Update request status
            let requestRef = self.db.collection("connectionRequests").document(requestId)
            batch.updateData([
                "status": "accepted",
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: requestRef)
            
            // Add to both users' friends arrays
            let currentUserRef = self.db.collection("users").document(currentUserId)
            let senderRef = self.db.collection("users").document(senderId)
            
            batch.updateData([
                "friends": FieldValue.arrayUnion([senderId])
            ], forDocument: currentUserRef)
            
            batch.updateData([
                "friends": FieldValue.arrayUnion([currentUserId])
            ], forDocument: senderRef)
            
            // Commit the batch
            batch.commit { error in
                if let error = error {
                    print("Error handling connection request: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func rejectConnectionRequest(requestId: String) {
        db.collection("connectionRequests").document(requestId).updateData([
            "status": "rejected"
        ])
    }
    
    private func addConnection(currentUserId: String, otherUserId: String) {
        // Add to current user's connections
        db.collection("users").document(currentUserId).updateData([
            "connections": FieldValue.arrayUnion([otherUserId])
        ])
        
        // Add to other user's connections
        db.collection("users").document(otherUserId).updateData([
            "connections": FieldValue.arrayUnion([currentUserId])
        ])
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
}

