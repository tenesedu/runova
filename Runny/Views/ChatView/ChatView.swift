import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatView: View {
    @StateObject var viewModel = ChatViewModel()
    @State private var showingNewGroupSheet = false
    @State private var showingActionSheet = false
    @State private var showingFriendsList = false
    
    var body: some View {
        NavigationView {
            ChatContentView(
                conversations: viewModel.conversations,
                showingNewGroupSheet: $showingNewGroupSheet,
                showingFriendsList: $showingFriendsList,
                showingActionSheet: $showingActionSheet,
                onCreateDirectChat: viewModel.createOrOpenDirectChat,
                onRefresh: viewModel.fetchConversations
            )
        }
    }
}

// Separate view for empty state
struct ChatEmptyStateView: View {
    var body: some View {
        EmptyStateView(
            message: "No Conversations Yet",
            systemImage: "bubble.left.and.bubble.right",
            description: "Start a chat with another runner or create a group!"
        )
    }
}

// Separate view for conversation list
struct ConversationListView: View {
    let conversations: [Conversation]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(conversations) { conversation in
                    NavigationLink(destination: ChatDetailView(conversation: conversation, allowsDismiss: true)) {
                        ConversationRow(conversation: conversation)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
}

// Main content view
struct ChatContentView: View {
    let conversations: [Conversation]
    @Binding var showingNewGroupSheet: Bool
    @Binding var showingFriendsList: Bool
    @Binding var showingActionSheet: Bool
    let onCreateDirectChat: (Runner) -> Void
    let onRefresh: () -> Void
    
    var body: some View {
        ZStack {
            if conversations.isEmpty {
                ChatEmptyStateView()
            } else {
                ConversationListView(conversations: conversations)
            }
        }
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ChatActionButton(showingActionSheet: $showingActionSheet)
            }
        }
        .confirmationDialog("New Chat", isPresented: $showingActionSheet) {
            Button("Create Group") { showingNewGroupSheet = true }
            Button("Start Chat") { showingFriendsList = true }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showingNewGroupSheet) {
            CreateGroupView { name, participants in
                onRefresh()
            }
        }
        .sheet(isPresented: $showingFriendsList) {
            FriendsListView { friend in
                onCreateDirectChat(friend)
                showingFriendsList = false
            }
        }
        .onAppear {
            onRefresh()
        }
    }
}

// Action button component
struct ChatActionButton: View {
    @Binding var showingActionSheet: Bool
    
    var body: some View {
        Button(action: { showingActionSheet = true }) {
            Image(systemName: "square.and.pencil")
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16))
            
            TextField("Search messages", text: $text)
                .font(.system(size: 16))
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
        )
    }
}



    
   

