import FirebaseFirestore
import FirebaseAuth

enum ConnectionStatus {
    case none
    case pending
    case connected
}

class ConnectionManager: ObservableObject {
    @Published var pendingRequests: [ConnectionRequest] = []
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
        
        db.collection("connectionRequests").document(requestId).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data(),
                  let fromUserId = data["fromUserId"] as? String else { return }
            
            // Update request status
            snapshot?.reference.updateData(["status": "accepted"])
            
            // Add to both users' connections
            self?.addConnection(currentUserId: currentUserId, otherUserId: fromUserId)
            
            // Remove the request from the pending requests
            if let index = self?.pendingRequests.firstIndex(where: { $0.id == requestId }) {
                self?.pendingRequests.remove(at: index)
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
        
        // Check if already connected
        db.collection("users").document(currentUserId).getDocument { snapshot, error in
            if let connections = snapshot?.data()?["connections"] as? [String],
               connections.contains(userId) {
                completion(.connected)
                return
            }
            
            // Check if there's a pending request
            self.db.collection("connectionRequests")
                .whereField("fromUserId", isEqualTo: currentUserId)
                .whereField("toUserId", isEqualTo: userId)
                .whereField("status", isEqualTo: "pending")
                .getDocuments { snapshot, error in
                    if snapshot?.documents.isEmpty == false {
                        completion(.pending)
                    } else {
                        completion(.none)
                    }
                }
        }
    }
    
    func fetchPendingRequests() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("connectionRequests")
            .whereField("toUserId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                self?.pendingRequests = documents.compactMap { document -> ConnectionRequest? in
                    let data = document.data()
                    guard let fromUserId = data["fromUserId"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp else { return nil }
                    
                    return ConnectionRequest(
                        id: document.documentID,
                        fromUserId: fromUserId,
                        timestamp: timestamp.dateValue()
                    )
                }
            }
    }
}

struct ConnectionRequest: Identifiable {
    let id: String
    let fromUserId: String
    let timestamp: Date
} 