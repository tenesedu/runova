import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PendingRequestRow: View {
    let request: ConnectionRequest
    @State private var senderProfile: Runner?
    @State private var showingProfile = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image and Info Button
            Button(action: {
                showingProfile = true
            }) {
                HStack {
                    // Profile Image
                    AsyncImage(url: URL(string: senderProfile?.profileImageUrl ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(Text("👤"))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(senderProfile?.name ?? "Loading...")
                            .font(.headline)
                        Text(request.createdAt, style: .relative)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Accept/Reject Buttons
            HStack(spacing: 15) {
                Button(action: {
                    handleRequest(action: "accepted")
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .imageScale(.large)
                }
                
                Button(action: {
                    handleRequest(action: "rejected")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .imageScale(.large)
                }
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingProfile) {
            if let profile = senderProfile {
                NavigationView {
                    RunnerDetailView(runner: profile)
                        .navigationBarItems(trailing: Button("Done") {
                            showingProfile = false
                        })
                }
            }
        }
        .onAppear {
            fetchSenderProfile()
        }
    }
    
    private func fetchSenderProfile() {
        let db = Firestore.firestore()
        db.collection("users").document(request.senderId).getDocument { snapshot, error in
            if let userData = snapshot?.data() {
                let user = UserApp(id: snapshot?.documentID ?? "", data: userData)
                self.senderProfile = Runner(user: user)
            }
        }
    }
    
    private func handleRequest(action: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Update request status
        let requestRef = db.collection("connectionRequests").document(request.id)
        batch.updateData([
            "status": action,
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: requestRef)
        
        if action == "accepted" {
            // Add to both users' friends arrays
            let currentUserRef = db.collection("users").document(currentUserId)
            let otherUserRef = db.collection("users").document(request.senderId)
            
            batch.updateData([
                "friends": FieldValue.arrayUnion([request.senderId])
            ], forDocument: currentUserRef)
            
            batch.updateData([
                "friends": FieldValue.arrayUnion([currentUserId])
            ], forDocument: otherUserRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error handling connection request: \(error.localizedDescription)")
            }
        }
    }
} 