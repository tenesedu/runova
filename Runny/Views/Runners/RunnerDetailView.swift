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
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Profile Image Section
                ZStack {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 300)
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                Text(runner.name)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(),
                                alignment: .bottomLeading
                            )
                    } else {
                        Rectangle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(maxWidth: .infinity, maxHeight: 300)
                            .overlay(
                                VStack {
                                    Text("👤")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                    Text(runner.name)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            )
                    }
                }
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
                    
                    
                    Button(action: startChat) {
                        HStack {
                            Image(systemName: "message.fill")
                            Text(NSLocalizedString("Message", comment: ""))
                        }
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 1)                             )
                    }
                }
                .padding(.horizontal)
                // Runner Info Section
                VStack(spacing: 20) {
                    infoCard(title: NSLocalizedString("Personal Information", comment: "")) {
                        InfoRow(icon: "person.fill", title: NSLocalizedString("Gender", comment: ""), value: runner.gender)
                        InfoRow(icon: "mappin.circle.fill", title: NSLocalizedString("City", comment: ""), value: runner.city)
                        InfoRow(icon: "calendar", title: NSLocalizedString("Age", comment: ""), value: "\(runner.age)")
                        InfoRow(icon: "clock", title: NSLocalizedString("Average Pace", comment: ""), value: "\(runner.averagePace)")
                    }
                    
                    infoCard(title: NSLocalizedString("Goals", comment: "")) {
                        ForEach(goals, id: \.self) { goal in
                            InfoRow(icon: "target", title: "", value: goal)
                        }
                    }
                    infoCard(title: NSLocalizedString("Interests", comment: "")) {
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
                
                
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(
            NavigationLink(
                destination: Group {
                    if let conversation = chatViewModel.selectedConversation {
                        ChatDetailView(conversation: conversation, allowsDismiss: true)
                    }
                },
                isActive: $chatViewModel.showChatDetail,
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
            return NSLocalizedString("Connect", comment: "")
        case .pending:
            return NSLocalizedString("Request Pending", comment: "")
        case .connected:
            return NSLocalizedString("Connected", comment: "")
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
            // Show immediate feedback
            connectionStatus = .pending
            connectionManager.sendConnectionRequest(to: runner.id)
            
        case .pending:
            connectionManager.cancelRequest(to: runner.id)
            connectionStatus = .none
            
        case .connected:
            connectionManager.removeConnection(with: runner.id)
            connectionStatus = .none
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
        chatViewModel.createOrOpenDirectChat(with: runner) { conversation in
            if let conversation = conversation {
                chatViewModel.selectedConversation = conversation
                chatViewModel.showChatDetail = true
            }
        }
    }
}

        
