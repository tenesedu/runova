//
//  ParticipantView.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 29/1/25.
//

import SwiftUI
import FirebaseAuth

struct ParticipantView: View {
    let user: UserApp
    @State var isSelected: Bool = false
    
    private var isCurrentUser: Bool {
        Auth.auth().currentUser?.uid == user.id
    }

    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: user.profileImageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            Text(isCurrentUser ? "You" :  user.name)
                .font(.system(size: 12))
                .lineLimit(1)
        }
        .frame(width: 60)
        .onTapGesture {
            if !isCurrentUser {
                isSelected = true
            }
        }
        .background(
            NavigationLink(
                destination: RunnerDetailView(runner: Runner(user: user)),
                isActive: $isSelected
            ) {
                EmptyView()
            }
            .hidden()
        )

    }
       
}

