import SwiftUI

struct RunCardView: View {
    let run: Run
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(run.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(run.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            Divider()
            
            // Details Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DetailItem(icon: "mappin.circle.fill", title: "Location", value: run.location)
                DetailItem(icon: "clock.fill", title: "Time", value: run.time.formatted(date: .abbreviated, time: .shortened))
                DetailItem(icon: "figure.run", title: "Distance", value: String(format: "%.1f km", run.distance))
                DetailItem(icon: "speedometer", title: "Pace", value: run.averagePace)
            }
            
            // Footer
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.blue)
                Text("\(run.currentParticipants.count)/\(run.maxParticipants) runners")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(run.terrain)
                    .font(.footnote)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            NavigationView {
                RunDetailView(run: run)
                    .navigationBarItems(trailing: Button("Done") {
                        showingDetail = false
                    })
            }
        }
    }
}

struct DetailItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.system(size: 12))
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
} 
