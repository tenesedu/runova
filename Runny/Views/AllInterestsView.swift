import SwiftUICore
import SwiftUI

struct AllInterestsView: View {
    let interests: [Interest]
    @Environment(\.dismiss) private var dismiss
    
    // Calculate grid items based on screen width
    private let gridItems = [
        GridItem(.adaptive(minimum: 280), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: gridItems, spacing: 16) {
                    ForEach(interests) { interest in
                        InterestCard(interest: interest)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("All Interests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
} 
