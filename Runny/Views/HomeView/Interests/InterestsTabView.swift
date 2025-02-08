import SwiftUI

    struct InterestsTabView: View {
        @State private var selectedTab = 0
        @Binding var interests: [Interest]
        @Binding var followedInterests: [Interest]
        
        var body: some View {
            VStack(alignment: .leading) {
                
                // Custom Tab Bar
                HStack(spacing: 24) {
                    TabButton(
                        title: NSLocalizedString("Discover", comment: ""),
                        icon: "sparkles",
                        isSelected: selectedTab == 0
                    ) {
                        withAnimation { selectedTab = 0 }
                    }
                    TabButton(
                        title: NSLocalizedString("Following", comment: ""),
                        icon: "heart.fill",
                        isSelected: selectedTab == 1
                    ) {
                        withAnimation { selectedTab = 1 }
                    }
                }
                .padding(.horizontal)
                
                // Content
                TabView(selection: $selectedTab) {
                    // Discover Tab
                    DiscoverInterestsView(
                        suggestedInterests: $interests,
                        followedInterests: $followedInterests
                    )
                    .tag(0)
                    
                    // Following Tab
                    FollowedInterestsView(suggestedInterests: $interests,
                                          followedInterests: $followedInterests)
                        .tag(1)
                }
                .frame(height: 190) // Set a fixed height for the TabView
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .onAppear {
                print("InterestsTabView appeared with \(interests.count) total interests")
            }
        }
    }

    // Custom Tab Button
    struct TabButton: View {
        let title: String
        let icon: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Rectangle()
                        .fill(isSelected ? Color.black : Color.clear)
                        .frame(height: 2)
                }
            }
            .foregroundColor(isSelected ? .black : .gray)
        }
    } 
