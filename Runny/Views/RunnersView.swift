import SwiftUI
import FirebaseFirestore

struct RunnersView: View {
    let runners: [Runner]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(runners) { runner in
                    RunnerCard(runner: runner)
                        .frame(height: 280)
                }
            }
            .padding()
        }
        .navigationTitle("All Runners")
        .navigationBarTitleDisplayMode(.inline)
    }
} 