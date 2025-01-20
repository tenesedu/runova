import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

class NotificationManager: ObservableObject {
    @Published var unreadNotifications = 0
    @Published var receivedRequests: [ConnectionRequest] = []
    @Published var acceptedRequests: [ConnectionRequest] = []
    private let db = Firestore.firestore()
    
    func fetchNotifications() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Fetch received requests
        db.collection("connectionRequests")
            .whereField("receiverId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "pending")
            .whereField("seen", isEqualTo: false) // Only fetch unseen requests
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.receivedRequests = documents.map {
                    ConnectionRequest(id: $0.documentID, data: $0.data())
                }
                self?.updateUnreadCount()
            }
        
        // Fetch accepted requests that haven't been seen
        db.collection("connectionRequests")
            .whereField("senderId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "accepted")
            .whereField("seen", isEqualTo: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self?.acceptedRequests = documents.map {
                    ConnectionRequest(id: $0.documentID, data: $0.data())
                }
                self?.updateUnreadCount()
            }
    }
    
    func markNotificationAsSeen(requestId: String) {
        db.collection("connectionRequests").document(requestId).updateData([
            "seen": true
        ]) { error in
            if let error = error {
                print("Error marking notification as seen: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    // Update local state
                    if let index = self.receivedRequests.firstIndex(where: { $0.id == requestId }) {
                        self.receivedRequests.remove(at: index)
                    }
                    if let index = self.acceptedRequests.firstIndex(where: { $0.id == requestId }) {
                        self.acceptedRequests.remove(at: index)
                    }
                    self.updateUnreadCount()
                }
            }
        }
    }
    
    private func updateUnreadCount() {
        unreadNotifications = receivedRequests.count + acceptedRequests.count
    }
} 
