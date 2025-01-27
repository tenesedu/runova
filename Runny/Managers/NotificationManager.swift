import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

class NotificationManager: ObservableObject {
    @Published var notifications: [UserNotification] = []
    @Published var unreadNotifications: Int = 0
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func fetchNotifications() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Remove existing listener if any
        listener?.remove()
        
        // Set up new listener
        listener = db.collection("notifications")
            .whereField("receiverId", isEqualTo: currentUserId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching notifications: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                
                self?.notifications = documents.map {
                    UserNotification(id: $0.documentID, data: $0.data())
                }
                
                self?.unreadNotifications = self?.notifications.filter { !$0.read }.count ?? 0
                print("Fetched \(documents.count) notifications, \(self?.unreadNotifications ?? 0) unread")
            }
    }
    
    func markAsRead(_ notificationId: String) {
        db.collection("notifications").document(notificationId).updateData([
            "read": true
        ])
    }
    
    func createNotification(
        notificationData: UserNotification,
        receiverId: String
    ) {
        guard !receiverId.isEmpty else {
            print("❌ Error: Receiver ID is empty.")
            return
        }
        
        // Prepare Firestore data
        let data: [String: Any] = [
            "type": notificationData.type.rawValue,
            "senderId": notificationData.senderId,
            "receiverId": receiverId,
            "timestamp": FieldValue.serverTimestamp(),
            "read": false,
            "senderName": notificationData.senderName,
            "senderProfileUrl": notificationData.senderProfileUrl,
            "relatedDocumentId": notificationData.relatedDocumentId ?? "",
            "runId": notificationData.runId ?? ""
        ]
        
        print("📬 Creating notification: \(data)")
        
        // Add the notification to Firestore
        db.collection("notifications").addDocument(data: data) { error in
            if let error = error {
                print("❌ Error creating notification: \(error.localizedDescription)")
            } else {
                print("✅ Notification created successfully!")
            }
        }
    }
    
    deinit {
        listener?.remove()
    }
}
