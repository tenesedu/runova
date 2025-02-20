import SwiftUI

struct DiscoverInterestsView: View {
    @Binding var suggestedInterests: [Interest]
    @Binding var followedInterests: [Interest]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(suggestedInterests.filter { !$0.isFollowed }) { interest in
                                    InterestCard(interest: interest, onFollowToggle: {
                                        followInterest(interest)
                                    })
                                }

            }
            .padding(.horizontal)
        }
    }
    
    private func followInterest(_ interest: Interest) {
        if let index = suggestedInterests.firstIndex(where: { $0.id == interest.id }) {
            suggestedInterests.remove(at: index)  // ✅ Remove from suggested
        }
        
        if !followedInterests.contains(where: { $0.id == interest.id }) {
            followedInterests.append(interest)  // ✅ Add to followed
        }
    }

    }
