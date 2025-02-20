import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PendingRequestRow: View {
    let request: ConnectionRequest
    @State private var senderProfile: Runner?
    @State private var showingProfile = false
    @StateObject private var connectionManager = ConnectionManager()
    
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
                    connectionManager.handleConnectionRequest(requestId: request.id ,action: "accepted")
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .imageScale(.large)
                }
                
                Button(action: {
                    connectionManager.handleConnectionRequest(requestId: request.id, action: "rejected")
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
}
