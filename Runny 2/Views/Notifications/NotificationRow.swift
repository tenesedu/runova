//
//  NotificationRow.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 23/1/25.
//

import SwiftUI
import Foundation
import FirebaseFirestore

struct NotificationRow: View {
    let notification: UserNotification
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: notification.senderProfileUrl)) { image in
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
                Text(notification.message)
                    .font(.system(size: 15))
                Text(notification.timestamp, style: .relative)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// Mock data for preview
let mockNotifications = UserNotification(
    id: "notification_1",
    data: [
        "type": "friend_accepted",
        "senderId": "user_789",
        "receiverId": "user_456",
        "timestamp": Timestamp(date: Date()),
        "read": false,
        "senderName": "Jane Smith",
        "senderProfileUrl": "https://example.com/jane.jpg",
        "relatedDocumentId": nil
    ]
)

#Preview {
    // Wrap the NotificationRow in a List or VStack for better preview
    List {
        NotificationRow(notification: mockNotifications)
    }
}
