import SwiftUI

struct ProfileImageView: View {
    let url: String
    var isGroup: Bool = false
    
    var body: some View {
        AsyncImage(url: URL(string: url)) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        } placeholder: {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    if isGroup {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.white)
                    } else {
                        Text("👤")
                    }
                }
        }
        .overlay(
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    HStack {
        ProfileImageView(url: "")
        ProfileImageView(url: "", isGroup: true)
    }
    .padding()
} 