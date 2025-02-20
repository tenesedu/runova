import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Image
                AsyncImage(url: URL(string: event.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(height: 200)
                .clipped()
                
                VStack(alignment: .leading, spacing: 20) {
                    // Event Title and Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text(event.type)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                        
                        Text(event.name)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    
                    // Date and Time
                    VStack(alignment: .leading, spacing: 4) {
                        Label {
                            Text(event.date, style: .date)
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        
                        Label {
                            Text(event.time)
                        } icon: {
                            Image(systemName: "clock")
                        }
                    }
                    .foregroundColor(.secondary)
                    
                    // Location
                    VStack(alignment: .leading, spacing: 4) {
                        Label(event.location, systemImage: "mappin.circle.fill")
                        Text(event.city)
                            .foregroundColor(.secondary)
                    }
                    
                    // Event Details
                    VStack(alignment: .leading, spacing: 16) {
                        // Distance and Difficulty
                        HStack(spacing: 20) {
                            VStack(alignment: .leading) {
                                Text("Distance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(event.distance))km")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Difficulty")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(event.difficulty.capitalized)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Terrain")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(event.terrain.capitalized)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        // Description
                        Text("About")
                            .font(.headline)
                        Text(event.description)
                            .foregroundColor(.secondary)
                        
                        // Amenities
                        if !event.amenities.isEmpty {
                            Text("Amenities")
                                .font(.headline)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(event.amenities, id: \.self) { amenity in
                                    Text(amenity)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
} 