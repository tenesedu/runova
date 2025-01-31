import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var selectedSegment: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab, selectedSegment: $selectedSegment)
                .tabItem {
                    Image(systemName: "house.fill")
                }
                .tag(0)
            
            FeedView()
                .tabItem {
                    Image(systemName: "map.fill")
                }
                .tag(1)
            
            RunsView(selectedSegment: $selectedSegment, selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "figure.run")
                }
                .tag(2)
            
            MapView()
                .tabItem {
                    Image(systemName: "globe")
                }
                .tag(3)
            
            ChatView()
                .tabItem {
                    Image(systemName: "message.fill")
                }
                .tag(4)
        }
        .accentColor(.black)
    }
} 
