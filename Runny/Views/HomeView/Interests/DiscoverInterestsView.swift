import SwiftUI

struct DiscoverInterestsView: View {
    @Binding var suggestedInterests: [Interest]
    @Binding var followedInterests: [Interest]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(suggestedInterests.filter { interest in
                    !followedInterests.contains(where: { $0.id == interest.id })
                }) { interest in
                    InterestCard(interest: interest)
                        .onTapGesture {
                            followedInterests.append(interest)
                        }
                }

            }
            .padding(.horizontal)
        }
    }
} 
