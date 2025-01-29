import SwiftUI

struct FollowedInterestsView: View {
    @Binding var interests: [Interest]
    
    var body: some View {
        if interests.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "heart")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text(NSLocalizedString("No followed interests yet", comment: ""))
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(interests) { interest in
                        InterestCard(interest: interest)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
} 
