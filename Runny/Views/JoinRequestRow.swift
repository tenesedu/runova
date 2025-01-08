import SwiftUI

struct JoinRequestRow: View {
    let request: JoinRequest
    let onAccept: () -> Void
    let onDecline: () -> Void
    @State private var userImage: UIImage?
    
    var body: some View {
        HStack(spacing: 12) {
            // User Avatar
            if let image = userImage {
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
                Text(request.userName)
                    .font(.headline)
                Text(request.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onDecline) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 24))
                }
                
                Button(action: onAccept) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 24))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
        .onAppear {
            loadUserImage()
        }
    }
    
    private func loadUserImage() {
        guard let imageUrl = request.userImage,
              let url = URL(string: imageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.userImage = image
                }
            }
        }.resume()
    }
} 