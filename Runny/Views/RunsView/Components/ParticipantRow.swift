import SwiftUI

struct ParticipantRow: View {
    let participant: Runner
    
    var body: some View {
        HStack {
            // Profile Image
            AsyncImage(url: URL(string: participant.profileImageUrl)) { image in
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
                Text(participant.name)
                    .font(.system(size: 16, weight: .medium))
                
                Text(participant.city)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
} 