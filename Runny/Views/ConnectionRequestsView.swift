import SwiftUI
import FirebaseFirestore

struct ConnectionRequestsView: View {
    @StateObject private var connectionManager = ConnectionManager()
    @State private var requests: [UserProfile] = []
    
    var body: some View {
        List(connectionManager.pendingRequests) { request in
            ConnectionRequestRow(request: request)
        }
        .navigationTitle("Connection Requests")
        .onAppear {
            connectionManager.fetchPendingRequests()
        }
    }
}

struct ConnectionRequestRow: View {
    let request: ConnectionRequest
    @StateObject private var connectionManager = ConnectionManager()
    @State private var senderProfile: UserProfile?
    @State private var showingProfile = false
    
    var body: some View {
        HStack {
            // Profile Image and Info Button
            Button(action: {
                showingProfile = true
            }) {
                HStack {
                    if let profileImage = senderProfile?.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(Text("👤").font(.system(size: 25)))
                    }
                    
                    // User Info
                    VStack(alignment: .leading) {
                        Text(senderProfile?.name ?? "Loading...")
                            .font(.headline)
                        Text(request.timestamp, style: .relative)
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
                    connectionManager.acceptConnectionRequest(requestId: request.id)
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .imageScale(.large)
                }
                
                Button(action: {
                    connectionManager.rejectConnectionRequest(requestId: request.id)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .imageScale(.large)
                }
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingProfile) {
            NavigationView {
                RunnerDetailView(runner: Runner(
                    id: request.fromUserId,
                    name: senderProfile?.name ?? "",
                    age: senderProfile?.age ?? "",
                    averagePace: senderProfile?.averagePace ?? "",
                    city: senderProfile?.city ?? "",
                    profileImageUrl: senderProfile?.profileImageUrl ?? "",
                    gender: senderProfile?.gender ?? ""
                ))
                .navigationBarItems(trailing: Button("Done") {
                    showingProfile = false
                })
            }
        }
        .onAppear {
            fetchSenderProfile()
        }
    }
    
    private func fetchSenderProfile() {
        let db = Firestore.firestore()
        db.collection("users").document(request.fromUserId).getDocument { snapshot, error in
            if let document = snapshot, document.exists,
               let data = document.data() {
                self.senderProfile = UserProfile(
                    id: document.documentID,
                    name: data["name"] as? String ?? "Unknown",
                    age: data["age"] as? String ?? "N/A",
                    averagePace: data["averagePace"] as? String ?? "N/A",
                    city: data["city"] as? String ?? "Unknown",
                    profileImageUrl: data["profileImageUrl"] as? String ?? "",
                    gender: data["gender"] as? String ?? "Not specified"
                )
                
                if let profileImageUrl = data["profileImageUrl"] as? String,
                   let url = URL(string: profileImageUrl) {
                    URLSession.shared.dataTask(with: url) { data, _, _ in
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self.senderProfile?.profileImage = image
                            }
                        }
                    }.resume()
                }
            }
        }
    }
}
