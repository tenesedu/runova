import SwiftUI
import FirebaseFirestore

struct NotificationsView: View {
    @StateObject private var notificationManager = NotificationManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingConnectionRequests = false
    @State private var selectedRequest: ConnectionRequest?
    @State private var showingUserProfile: Runner?
    
    var body: some View {
        NavigationView {
            List {
                // Connection Request Notifications
                ForEach(notificationManager.receivedRequests) { request in
                    NotificationRow(
                        type: .receivedRequest,
                        request: request,
                        onTap: {
                            notificationManager.markNotificationAsSeen(requestId: request.id)
                            selectedRequest = request
                            showingConnectionRequests = true
                            dismiss() // Dismiss notifications view
                        }
                    )
                }
                
                // Accepted Request Notifications
                ForEach(notificationManager.acceptedRequests) { request in
                    NotificationRow(
                        type: .acceptedRequest,
                        request: request,
                        onTap: {
                            notificationManager.markNotificationAsSeen(requestId: request.id)
                            // Fetch and show user profile
                            let db = Firestore.firestore()
                            db.collection("users").document(request.senderId).getDocument { snapshot, error in
                                if let userData = snapshot?.data() {
                                    let user = UserApp(id: snapshot?.documentID ?? "", data: userData)
                                    showingUserProfile = Runner(user: user)
                                }
                            }
                        }
                    )
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingConnectionRequests) {
            ConnectionRequestsView()
        }
        .sheet(item: $showingUserProfile) { runner in
            NavigationView {
                RunnerDetailView(runner: runner)
                    .navigationBarItems(trailing: Button("Done") {
                        showingUserProfile = nil
                    })
            }
        }
        .onAppear {
            notificationManager.fetchNotifications()
        }
    }
}

struct NotificationRow: View {
    enum NotificationType {
        case receivedRequest
        case acceptedRequest
    }
    
    let type: NotificationType
    let request: ConnectionRequest
    let onTap: () -> Void
    @State private var userProfile: Runner?
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: userProfile?.profileImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(Text("👤"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notificationText)
                        .font(.system(size: 15))
                    Text(request.createdAt, style: .relative)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            fetchUserProfile()
        }
    }
    
    private var notificationText: String {
        let name = userProfile?.name ?? "Someone"
        switch type {
        case .receivedRequest:
            return "\(name) sent you a connection request"
        case .acceptedRequest:
            return "\(name) accepted your connection request"
        }
    }
    
    private func fetchUserProfile() {
        let db = Firestore.firestore()
        let userId = type == .receivedRequest ? request.senderId : request.receiverId
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let userData = snapshot?.data() {
                let user = UserApp(id: snapshot?.documentID ?? "", data: userData)
                self.userProfile = Runner(user: user)
            }
        }
    }
}

