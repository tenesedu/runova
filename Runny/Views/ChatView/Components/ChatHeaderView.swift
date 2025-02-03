import SwiftUI
import FirebaseAuth

struct ChatHeaderView: View {
    let conversation: Conversation
    let participants: [Runner]
    let onBackTap: () -> Void
    let onInfoTap: () -> Void
    @State private var showingProfile = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBackTap) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Button(action: {
                if conversation.type == "direct" {
                    showingProfile = true
                } else {
                    onInfoTap()
                }
            }) {
                HStack {
                    if conversation.type == "direct" {
                        UserProfileImage(url: conversation.otherUserProfile?.profileImageUrl)
                    } else {
                        GroupProfileImage(url: conversation.groupImageUrl)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(headerTitle)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if conversation.type == "group" {
                            Text(NSLocalizedString("Group", comment: ""))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Spacer()
            
            if conversation.type == "group" {
                Button(action: onInfoTap) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }
        }
        .background(Color.clear)
        .navigationDestination(isPresented: $showingProfile) {
            if conversation.type == "direct",
                let otherUser = conversation.otherUserProfile {
                if let runner = participants.first(where: { $0.id == otherUser.id }) {
                    RunnerDetailView(runner: runner)
                } else {
                    Text("User not found")
                }
            }
        }
    }
    
    private var headerTitle: String {
        if conversation.type == "direct" {
            return conversation.otherUserProfile?.name ?? "Chat"
        } else {
            return conversation.groupName ?? "Group"
        }
    }
    
    private var participantsText: String {
        let currentUserId = Auth.auth().currentUser?.uid
        let participantNames = participants.map { participant in
            if participant.id == currentUserId {
                return "You"
            } else {
                return participant.name
            }
        }
        return participantNames.joined(separator: ", ")
    }
}

