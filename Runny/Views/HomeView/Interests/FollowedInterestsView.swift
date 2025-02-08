import SwiftUI

struct FollowedInterestsView: View {
    @Binding var suggestedInterests: [Interest]
    @Binding var followedInterests: [Interest]
    
    var body: some View {
        if followedInterests.isEmpty {
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
                    ForEach(followedInterests) { interest in
                        InterestCard(interest: interest, onFollowToggle: {
                            unfollowInterest(interest)
                        })
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
        
    private func unfollowInterest(_ interest: Interest) {
        if let index = followedInterests.firstIndex(where: { $0.id == interest.id }) {
            followedInterests.remove(at: index)
        }
        
        if !suggestedInterests.contains(where: { $0.id == interest.id }) {
            var updatedInterest = interest
            updatedInterest.isFollowed = false
            suggestedInterests.append(updatedInterest) 
        }
    }

    }

