import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SentRequestRow: View {
    let request: ConnectionRequest
    @State private var receiverProfile: Runner?
    @State private var showingProfile = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image and Info Button
            Button(action: {
                showingProfile = true
            }) {
                HStack {
                    // Profile Image
                    AsyncImage(url: URL(string: receiverProfile?.profileImageUrl ?? "")) { image in
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
                        Text(receiverProfile?.name ?? "Loading...")
                            .font(.headline)
                        Text(request.createdAt, style: .relative)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Cancel Request Button
            Button(action: {
                cancelRequest()
            }) {
                Text("Cancel")
                    .foregroundColor(.red)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red, lineWidth: 1)
                    )
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingProfile) {
            if let profile = receiverProfile {
                NavigationView {
                    RunnerDetailView(runner: profile)
                        .navigationBarItems(trailing: Button("Done") {
                            showingProfile = false
                        })
                }
            }
        }
        .onAppear {
            fetchReceiverProfile()
        }
    }
    
    private func fetchReceiverProfile() {
        let db = Firestore.firestore()
        db.collection("users").document(request.receiverId).getDocument { snapshot, error in
            if let userData = snapshot?.data() {
                let user = UserApp(id: snapshot?.documentID ?? "", data: userData)
                self.receiverProfile = Runner(user: user)
            }
        }
    }
    
    private func cancelRequest() {
        let db = Firestore.firestore()
        db.collection("connectionRequests").document(request.id).updateData([
            "status": "cancelled",
            "updatedAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error cancelling request: \(error.localizedDescription)")
            }
        }
    }
} 