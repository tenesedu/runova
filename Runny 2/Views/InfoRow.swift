import SwiftUI

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            if !title.isEmpty {
                Text(title)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(value)
                .foregroundColor(.primary)
        }
    }
} 