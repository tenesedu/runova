import SwiftUI

struct ParticipantRow: View {
    let participant: UserProfile
    
    var body: some View {
        HStack(spacing: 12) {
            // User Avatar
            if let image = participant.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(Text("👤"))
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(participant.name)
                    .font(.headline)
                Text(participant.city)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Pace Info
            Text(participant.averagePace)
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
} 