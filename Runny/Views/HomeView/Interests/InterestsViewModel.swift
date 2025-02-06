import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class InterestsViewModel: ObservableObject {
    @Published var interests: [Interest] = []
    @Published var followedInterests: [Interest] = []
    @Published var hasLoadedInterests = false
    
    init() {
        setupNotificationObserver()
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("InterestFollowStatusChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let interest = notification.userInfo?["interest"] as? Interest,
                  let isFollowing = notification.userInfo?["isFollowing"] as? Bool else {
                return
            }
            
            if isFollowing {
                self.interests.removeAll { $0.id == interest.id }
                self.followedInterests.append(interest)
            } else {
                self.followedInterests.removeAll { $0.id == interest.id }
                self.interests.append(interest)
            }
        }
    }
    
    @MainActor
    func fetchInterests() async {
        let db = Firestore.firestore()
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            return
        }
        
        do {
            let querySnapshot = try await db.collection("interests").order(by: "name").getDocuments()
            
            var allInterests = querySnapshot.documents.map { document in
                Interest(id: document.documentID, data: document.data())
            }
            
            var followedInterests: [Interest] = []
            let group = DispatchGroup()
            
            for interest in allInterests {
                group.enter()
                
                db.collection("interests")
                    .document(interest.id)
                    .collection("followers")
                    .document(userId)
                    .getDocument { [weak self] (document, error) in
                        if let error = error {
                            print("❌ Error checking follower for \(interest.name): \(error)")
                        } else if document?.exists == true {
                            followedInterests.append(interest)
                            allInterests.removeAll { $0.id == interest.id }
                        }
                        group.leave()
                    }
            }
            
            group.notify(queue: .main) { [weak self] in
                self?.interests = allInterests
                self?.interests.shuffle()
                self?.followedInterests = followedInterests
                self?.hasLoadedInterests = true
                print("✅ Interests loaded - Total: \(allInterests.count), Following: \(followedInterests.count)")
            }
            
        } catch {
            print("❌ Error fetching interests: \(error.localizedDescription)")
        }
    }
} 
