//
//  CommentRowView.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 18/2/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CommentRow: View {
    
    let comment: Comment
    
    @State private var userImageUrl: String? = nil
    @State private var userName: String? = nil
    
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            AsyncImage(url: URL(string: userImageUrl ?? "")) { phase in
                switch phase {
                case .empty:
                    Circle().fill(Color.gray.opacity(0.3))
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Circle().fill(Color.gray.opacity(0.3))
                }
                
                
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                
                HStack {
                    Text(userName ?? "")
                        .font(.system(size: 14, weight: .semibold))
                    Text(comment.createdAt.timeAgo())
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                Text(comment.text)
                    .font(.system(size: 14))
                
                HStack(spacing: 16){
                    Button(action: {
                        
                    }){
                        HStack(spacing: 4){
                            Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                                .foregroundColor(comment.isLiked ? .red : .gray)
                            Text("\(comment.likesCount)")
                                
                        }
                    }
                    
                    Button(action: {
                        
                    }){
                        HStack(spacing: 4){
                            Image(systemName: "bubble.left")
                                .foregroundColor(.gray)
                            Text("\(comment.repliesCount)")
                             
                        }
                    }
                }//HStack
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.top, 8)
                
            }//VStack
                
        }
        .padding(.vertical, 8)
        .onAppear {
            UserManager.shared.getUserData(by: comment.userId) { user in
                if let user = user {
                    self.userName = user.name
                    self.userImageUrl = user.profileImageUrl
                }
            }
        }
    }
}

let mockPost = "post123" // ID del post al que pertenecen los comentarios

let mockComment: [Comment] = [
    Comment(
        id: "comment1",
        data: [
            "text": "Este es un comentario principal.",
            "userId": "user1",
            "userName": "iOSDev",
            "userImageUrl": "https://example.com/profile1.jpg",
            "createdAt": Timestamp(date: Date()),
            "parentId": nil, // Es un comentario principal
            "mentionedUserName": nil,
            "likesCount": 5
        ],
        postId: mockPostId
    ),
    Comment(
        id: "comment2",
        data: [
            "text": "@iOSDev Esta es una respuesta a tu comentario.",
            "userId": "user2",
            "userName": "Reactivo",
            "userImageUrl": "https://example.com/profile2.jpg",
            "createdAt": Timestamp(date: Date()),
            "parentId": "comment1", // Respuesta al comentario 1
            "mentionedUserName": "iOSDev",
            "likesCount": 3
        ],
        postId: mockPostId
    ),
    Comment(
        id: "comment3",
        data: [
            "text": "Otro comentario principal.",
            "userId": "user3",
            "userName": "AppleFan",
            "userImageUrl": "https://example.com/profile3.jpg",
            "createdAt": Timestamp(date: Date()),
            "parentId": nil, // Es un comentario principal
            "mentionedUserName": nil,
            "likesCount": 2
        ],
        postId: mockPostId
    )
]

#Preview {
    CommentRow(comment: mockComments[0])
}

