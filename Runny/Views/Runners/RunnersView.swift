import SwiftUI
import FirebaseFirestore

struct RunnersView: View {
    let runners: [Runner]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(runners) { runner in
                    NavigationLink(destination: RunnerDetailView(runner: runner)) {
                        runnerCard(for: runner)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("All Runners")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func runnerCard(for runner: Runner) -> some View {
        ZStack(alignment: .bottom) {
            // Background Image
            AsyncImage(url: URL(string: runner.profileImageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 120, height: 160)
            .clipped()
            
            // Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    .clear,
                    .black.opacity(0.3),
                    .black.opacity(0.7)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Runner Info
            VStack(alignment: .leading, spacing: 4) {
                Text(runner.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    // Age
                    Label(runner.age, systemImage: "person.fill")
                        .font(.system(size: 11))
                    
                    // Pace
                    Label("\(runner.averagePace) /km", systemImage: "figure.run")
                        .font(.system(size: 11))
                }
                .foregroundColor(.white.opacity(0.9))
                
                // City
                Label(runner.city, systemImage: "mappin.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 120, height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
} 
