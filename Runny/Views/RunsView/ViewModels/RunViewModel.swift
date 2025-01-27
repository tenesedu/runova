import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class RunViewModel: ObservableObject {
    @Published var hasRequestedToJoin: [String: Bool] = [:]
    
    func checkJoinRequest(for run: Run) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let joinRequestRef = db.collection("runs").document(run.id)
                          .collection("joinRequests").document(userId)
        
        joinRequestRef.getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error checking join request: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                if let snapshot = snapshot, snapshot.exists {
                    let status = snapshot.data()?["status"] as? String ?? ""
                    self?.hasRequestedToJoin[run.id] = status == "pending"
                } else {
                    self?.hasRequestedToJoin[run.id] = false
                }
            }
        }
    }
    
    func requestToJoin(run: Run) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let joinRequestRef = db.collection("runs").document(run.id)
                          .collection("joinRequests").document(userId)
        
        let requestData: [String: Any] = [
            "userId": userId,
            "status": "pending",
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        joinRequestRef.setData(requestData) { [weak self] error in
            if let error = error {
                print("Error requesting to join run: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self?.hasRequestedToJoin[run.id] = true
                }
                print("Successfully requested to join run")
            }
        }
    }
} 
