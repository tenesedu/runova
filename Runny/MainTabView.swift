import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var selectedSegment: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab, selectedSegment: $selectedSegment)
                .tabItem {
                    VStack {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    
                }
                .tag(0)
            
            FeedView()
                .tabItem {
                    Image(systemName: "rectangle.grid.3x2.fill")
                    Text("Feed")
                }
                .tag(1)
            
            RunsView(selectedSegment: $selectedSegment, selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "figure.run")
                    Text("Runs")
                }
                .tag(2)
            
            MapView()
                .tabItem {
                    Image(systemName: "globe")
                    Text("Map")
                }
                .tag(3)
            
            ChatView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
                .tag(4)
        }
        .accentColor(.black)
    }
} 

#Preview {
    MainTabView()
}
