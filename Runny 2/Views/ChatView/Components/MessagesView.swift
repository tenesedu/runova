//
//  MessagesView.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 21/1/25.
//

import SwiftUI
import FirebaseAuth

struct MessagesView: View {
    let messages: [Message]
    let isGroupChat: Bool

    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(
                            message: message,
                            isFromCurrentUser: message.senderId == Auth.auth().currentUser?.uid,
                            showSenderInfo: isGroupChat
                        )
                        .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) { oldCount, newCount in
                if newCount > oldCount {
                    withAnimation {
                        if let lastId = messages.last?.id {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            .onAppear {
                if let lastId = messages.last?.id {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
    }
}



struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    let showSenderInfo: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !isFromCurrentUser {
                if showSenderInfo {
                    // Profile Image (only for other users in group chats)
                    AsyncImage(url: URL(string: message.senderProfileUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 45, height: 45)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 45, height: 45)
                            .overlay(Image(systemName: "person.fill"))
                    }
                }
                
                // Message Content and Timestamp for other users
                VStack(alignment: .leading, spacing: 4) {
                    if showSenderInfo {
                        Text(message.senderName)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text(message.content)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .clipShape(MessageBubbleShape(isFromCurrentUser: false))
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            } else {
                // Current user's messages
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(MessageBubbleShape(isFromCurrentUser: true))
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

// Custom Shape for Message Bubble
struct MessageBubbleShape: Shape {
    let isFromCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: isFromCurrentUser ? [.topLeft, .topRight, .bottomLeft] : [.bottomLeft, .topRight, .bottomRight],
            cornerRadii: CGSize(width: 20, height: 20)
        )
        return Path(path.cgPath)
    }
}

// Type eraser for Shape
struct AnyShape: Shape {
    private let path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        self.path = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        return path(rect)
    }
}

#Preview {
    let mockMessages = [
        Message(
            id: "1",
            conversationId: "123",
            senderId: "user1",
            content: "Hello!",
            timestamp: Date(),
            senderName: "joaqui",
            senderProfileUrl: "https://example.com/alice.jpg"
        ),
        Message(
            id: "2",
            conversationId: "123",
            senderId: "user2",
            content: "Hi there!",
            timestamp: Date(),
            senderName: "John Doe",
            senderProfileUrl: "https://example.com/john.jpg"
        ),
        Message(
            id: "3",
            conversationId: "123",
            senderId: "user1",
            content: "How are you?",
            timestamp: Date(),
            senderName: "Alice",
            senderProfileUrl: "https://example.com/alice.jpg"
        )
    ]
    
    return MessagesView(
        messages: mockMessages,
        isGroupChat: true
    )
}
