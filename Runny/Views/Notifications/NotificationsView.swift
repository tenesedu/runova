import SwiftUI
import FirebaseFirestore

struct NotificationsView: View {
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var connectionManager = ConnectionManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingConnectionRequests = false
    @State private var selectedUser: UserApp?
    @State private var showingUserProfile = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                if showingUserProfile, let user = selectedUser {
                    // Show RunnerDetailView when showingUserProfile is true
                    RunnerDetailView(runner: Runner(user: user))
                        .navigationTitle("Profile")
                        .navigationBarTitleDisplayMode(.inline)
                } else if showingConnectionRequests {
                    // Show ConnectionsView when showingConnectionRequests is true
                    ConnectionsView(selectedTab: 1)
                } else {
                    // Show NotificationsView when neither showingUserProfile nor showingConnectionRequests is true
                    if notificationManager.notifications.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No notifications yet")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGroupedBackground))
                    } else {
                        List {
                            ForEach(notificationManager.notifications) { notification in
                                NotificationRow(notification: notification)
                                    .onTapGesture {
                                        handleNotificationTap(notification)
                                    }
                                    .listRowBackground(notification.read ? Color.clear : Color.blue.opacity(0.1))
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle(showingConnectionRequests ? "Connections" : "Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing:
                Button(action: {
                    if showingConnectionRequests || showingUserProfile {
                        // Go back to NotificationsView
                        showingConnectionRequests = false
                        showingUserProfile = false
                    } else {
                        // Dismiss the entire view
                        dismiss()
                    }
                }) {
                    Text((showingConnectionRequests || showingUserProfile) ? "Back" : "Done")
                }
            )
        }
        .onAppear {
            notificationManager.fetchNotifications()
        }
    }
    
    private func handleNotificationTap(_ notification: UserNotification) {
        notificationManager.markAsRead(notification.id)
        
        switch notification.type {
        case .friendRequest:
            selectedTab = 0
            showingConnectionRequests = true
            
        case .friendAccepted:
            let db = Firestore.firestore()
            db.collection("users").document(notification.senderId).getDocument { snapshot, error in
                if let userData = snapshot?.data() {
                    selectedUser = UserApp(id: snapshot?.documentID ?? "", data: userData)
                    showingUserProfile = true
                }
            }
        case .messageReceived, .eventInvitation:
            break
        }
    }
}

#Preview {
    NotificationsView()
}
