import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class RunViewModel: ObservableObject {
    @Published var hasRequestedToJoin: [String: Bool] = [:]
    private let notificationManager = NotificationManager()
    private var statusListeners: [String: ListenerRegistration] = [:] // Add this to store listeners
    
    func checkJoinRequestStatus(for run: Run) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Remove existing listener if any
        statusListeners[run.id]?.remove()
        
        // First check if user is already a participant
        if run.currentParticipants.contains(userId) {
            DispatchQueue.main.async {
                self.hasRequestedToJoin[run.id] = false
            }
            return
        }
        
        // Then listen to pending requests
        let db = Firestore.firestore()
        let joinRequestRef = db.collection("runs").document(run.id)
                              .collection("joinRequests").document(userId)
        
        let listener = joinRequestRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error checking join request status: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                if let data = snapshot?.data(),
                   let status = data["status"] as? String {
                    self?.hasRequestedToJoin[run.id] = status == "pending"
                } else {
                    self?.hasRequestedToJoin[run.id] = false
                }
            }
        }
        
        // Store the listener
        statusListeners[run.id] = listener
    }
    
    // Add cleanup method
    func stopListening(for runId: String) {
        statusListeners[runId]?.remove()
        statusListeners.removeValue(forKey: runId)
    }
    
    // Clean up all listeners
    deinit {
        statusListeners.values.forEach { $0.remove() }
        statusListeners.removeAll()
    }
    
    func requestToJoin(run: Run) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let joinRequestRef = db.collection("runs").document(run.id)
                              .collection("joinRequests").document(userId)
        
        // Fetch the user's data
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("❌ Error fetching user's info: \(error.localizedDescription)")
                return
            }
            
            guard let data = document?.data() else {
                print("❌ User's data not found in Firestore")
                return
            }
            
            let userName = data["name"] as? String ?? "Unknown"
            let userImage = data["profileImageUrl"] as? String ?? ""
            
            // Create the JoinRequest object
            let requestData = JoinRequest(
                id: userId,
                status: "pending",
                userId: userId,
                userName: userName,
                userImage: userImage,
                timestamp: Date()
            )
            
            // Save the join request to Firestore
            joinRequestRef.setData(requestData.toDictionary()) { [weak self] error in
                if let error = error {
                    print("❌ Error requesting to join run: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self?.hasRequestedToJoin[run.id] = true
                    }
                    print("✅ Successfully requested to join run")
                    
                    // Create a notification for the run creator
                    let notification = UserNotification(
                        type: .joinRequest,
                        senderId: userId,
                        receiverId: run.createdBy,
                        senderName: userName,
                        senderProfileUrl: userImage,
                        relatedDocumentId: joinRequestRef.documentID,
                        runId: run.id
                    )
                    
                    // Send the notification
                    self?.notificationManager.createNotification(notificationData: notification, receiverId: run.createdBy)
                }
            }
        }
    }
    
    
    
}
