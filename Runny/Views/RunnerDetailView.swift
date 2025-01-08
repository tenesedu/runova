import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct RunnerDetailView: View {
    let runner: Runner
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @State private var profileImage: UIImage?
    @State private var interests: [String] = []
    @State private var goals: [String] = []
    @StateObject private var connectionManager = ConnectionManager()
    @State private var connectionStatus: ConnectionStatus = .none
    @State private var showingChat = false
    @State private var selectedConversation: Conversation?
    @State private var isNavigatingToChat = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Profile Image Section
                ZStack {
                    Color.blue.opacity(0.1)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                    
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(radius: 10)
                    } else {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 120, height: 120)
                            .overlay(Text("👤").font(.system(size: 60)))
                            .shadow(radius: 10)
                    }
                }
                .padding(.bottom)
                
                // User Info Section
                VStack(spacing: 20) {
                    Text(runner.name)
                        .font(.system(size: 28, weight: .bold))
                    
                    infoCard(title: "Personal Information") {
                        InfoRow(icon: "person.fill", title: "Gender", value: runner.gender)
                        InfoRow(icon: "mappin.circle.fill", title: "City", value: runner.city)
                        InfoRow(icon: "calendar", title: "Age", value: "\(runner.age)")
                        InfoRow(icon: "clock", title: "Average Pace", value: "\(runner.averagePace)")
                    }
                    
                    infoCard(title: "Goals") {
                        ForEach(goals, id: \.self) { goal in
                            InfoRow(icon: "target", title: "", value: goal)
                        }
                    }
                    
                    infoCard(title: "Interests") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                            ForEach(interests, id: \.self) { interest in
                                Text(interest)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Action Buttons
                HStack(spacing: 15) {
                    // Connect Button
                    Button(action: handleConnectionAction) {
                        HStack {
                            Image(systemName: connectionButtonIcon)
                            Text(connectionButtonTitle)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(connectionButtonColor)
                        .cornerRadius(10)
                    }
                    
                    // Message Button
                    Button(action: startChat) {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Message")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(
            NavigationLink(
                destination: Group {
                    if let conversation = selectedConversation {
                        ChatDetailView(conversation: conversation)
                    }
                },
                isActive: $isNavigatingToChat,
                label: { EmptyView() }
            )
        )
        .onAppear {
            loadProfileImage()
            fetchRunnerDetails()
            connectionManager.checkConnectionStatus(with: runner.id) { status in
                connectionStatus = status
            }
        }
    }
    
    private func infoCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            
            content()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private func loadProfileImage() {
        guard let url = URL(string: runner.profileImageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            }
        }.resume()
    }
    
    private func fetchRunnerDetails() {
        let db = Firestore.firestore()
        db.collection("users").document(runner.id).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                self.interests = data?["interests"] as? [String] ?? []
                self.goals = data?["goals"] as? [String] ?? []
            }
        }
    }
    
    private var connectionButtonTitle: String {
        switch connectionStatus {
        case .none:
            return "Connect"
        case .pending:
            return "Request Pending"
        case .connected:
            return "Connected"
        }
    }
    
    private var connectionButtonColor: Color {
        switch connectionStatus {
        case .none:
            return .blue
        case .pending:
            return .gray
        case .connected:
            return .green
        }
    }
    
    private func handleConnectionAction() {
        switch connectionStatus {
        case .none:
            connectionManager.sendConnectionRequest(to: runner.id)
            connectionStatus = .pending
        default:
            break
        }
    }
    
    private var connectionButtonIcon: String {
        switch connectionStatus {
        case .none:
            return "person.badge.plus"
        case .pending:
            return "clock"
        case .connected:
            return "checkmark"
        }
    }
    
    private func startChat() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Check if conversation already exists
        db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching conversations: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    // Look for existing conversation with this user
                    let existingConversation = documents.first { document in
                        let data = document.data()
                        let participants = data["participants"] as? [String] ?? []
                        return participants.contains(runner.id)
                    }
                    
                    if let existing = existingConversation {
                        // Use existing conversation
                        let data = existing.data()
                        self.selectedConversation = Conversation(
                            id: existing.documentID,
                            otherUserId: runner.id,
                            lastMessage: data["lastMessage"] as? String ?? "",
                            lastMessageTime: (data["lastMessageTime"] as? Timestamp)?.dateValue() ?? Date(),
                            unreadCount: data["unreadCount.\(currentUserId)"] as? Int ?? 0,
                            otherUserProfile: UserProfile(
                                id: runner.id,
                                name: runner.name,
                                age: runner.age,
                                averagePace: runner.averagePace,
                                city: runner.city,
                                profileImageUrl: runner.profileImageUrl,
                                gender: runner.gender
                            )
                        )
                        self.isNavigatingToChat = true
                    } else {
                        // Create new conversation
                        let newConversationRef = db.collection("conversations").document()
                        let conversationData: [String: Any] = [
                            "participants": [currentUserId, runner.id],
                            "lastMessage": "",
                            "lastMessageTime": FieldValue.serverTimestamp(),
                            "unreadCount": [
                                currentUserId: 0,
                                runner.id: 0
                            ]
                        ]
                        
                        newConversationRef.setData(conversationData) { error in
                            if let error = error {
                                print("Error creating conversation: \(error.localizedDescription)")
                                return
                            }
                            
                            self.selectedConversation = Conversation(
                                id: newConversationRef.documentID,
                                otherUserId: runner.id,
                                lastMessage: "",
                                lastMessageTime: Date(),
                                unreadCount: 0,
                                otherUserProfile: UserProfile(
                                    id: runner.id,
                                    name: runner.name,
                                    age: runner.age,
                                    averagePace: runner.averagePace,
                                    city: runner.city,
                                    profileImageUrl: runner.profileImageUrl,
                                    gender: runner.gender
                                )
                            )
                            self.isNavigatingToChat = true
                        }
                    }
                }
            }
    }
} 