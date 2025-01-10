import SwiftUI

struct RunCardView: View {
    let run: Run
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(alignment: .leading, spacing: 0) {
                // Premium Header with Gradient Overlay
                ZStack(alignment: .topLeading) {
                    // Background Pattern
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.15),
                                    Color.purple.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 100)
                    
                    // Decorative Pattern
                    HStack(spacing: 2) {
                        ForEach(0..<10) { _ in
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 1)
                        }
                    }
                    .rotationEffect(.degrees(45))
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(run.name)
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text(run.description)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            // Premium Badge Design
                            Text(run.terrain)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 0.5)
                                        )
                                )
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                }
                
                // Info Grid with Elegant Design
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        MetricView(
                            icon: "clock.fill",
                            iconColor: .orange,
                            value: run.time.formatted(date: .abbreviated, time: .shortened),
                            title: "Time"
                        )
                        
                        MetricView(
                            icon: "mappin.circle.fill",
                            iconColor: .red,
                            value: run.location,
                            title: "Location"
                        )
                    }
                    
                    Divider()
                        .background(Color.gray.opacity(0.1))
                    
                    HStack(spacing: 20) {
                        MetricView(
                            icon: "figure.run",
                            iconColor: .green,
                            value: String(format: "%.1f km", run.distance),
                            title: "Distance"
                        )
                        
                        MetricView(
                            icon: "speedometer",
                            iconColor: .blue,
                            value: run.averagePace,
                            title: "Pace"
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                // Premium Footer Design
                HStack {
                    // Elegant Participants Display
                    ZStack(alignment: .leading) {
                        ForEach(0..<min(3, run.currentParticipants.count), id: \.self) { index in
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.blue)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color(.systemBackground), lineWidth: 1.5)
                                )
                                .offset(x: CGFloat(index * 15))
                        }
                    }
                    .frame(width: 60, alignment: .leading)
                    
                    Text("\(run.currentParticipants.count)/\(run.maxParticipants)")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Join Button
                    HStack(spacing: 4) {
                        Text("Join")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .frame(width: 300, height: 280) // Fixed size for consistency
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.5),
                                .clear,
                                .white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 15,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(PlainButtonStyle())
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

// Premium Metric View Component
struct MetricView: View {
    let icon: String
    let iconColor: Color
    let value: String
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
