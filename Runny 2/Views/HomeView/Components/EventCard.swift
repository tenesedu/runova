import SwiftUICore
import SwiftUI
struct EventCard: View {
    let event: Event
    
    var body: some View {
        NavigationLink(destination: EventDetailView(event: event)) {
            VStack(alignment: .leading, spacing: 0) {
                // Event Image
                AsyncImage(url: URL(string: event.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 120)
                .clipped()
                
                // Event Info
                VStack(alignment: .leading, spacing: 8) {
                    // Date and Type
                    HStack {
                        Text(event.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(event.type)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                    
                    // Event Name
                    Text(event.name)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    // Location and Distance
                    HStack {
                        Label(event.city, systemImage: "mappin.circle.fill")
                        Spacer()
                        Label("\(Int(event.distance))km", systemImage: "figure.run")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(12)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
} 
