import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

struct HomeView: View {
    @State private var users: [UserApp] = []
    @State private var interests: [Interest] = []
    @State private var isLoading = true
    @State private var showingProfile = false
    @State private var showingAllRunners = false
    @State private var userName: String = ""
    @State private var profileImageUrl: String = ""
    @State private var searchText: String = ""
    @State private var showingNotifications = false
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationManager = NotificationManager()
    @State private var isSearchActive = false
    @State private var followedInterests: [Interest] = []
    
    @Binding var selectedTab: Int
    @Binding var selectedSegment: Int
    
    var filteredRunners: [Runner] {
        if searchText.isEmpty {
            return users.map { Runner(user: $0) }
        }
        return users.filter { user in
            user.name.localizedCaseInsensitiveContains(searchText) ||
            user.city.localizedCaseInsensitiveContains(searchText)
        }.map { Runner(user: $0) }
    }
    
    var filteredInterests: [Interest] {
        if searchText.isEmpty {
            return interests
        }
        return interests.filter { interest in
            interest.name.localizedCaseInsensitiveContains(searchText.localized)
        }
    }
    
    var nearbyRunners: [Runner] {
        guard let currentLocation = locationManager.location else { 
            print("No location available")
            return [] 
        }
        
        return users
            .filter { user in
                user.id != Auth.auth().currentUser?.uid && 
                user.locationAsCLLocation() != nil // Only include users with valid locations
            }
            .sorted { user1, user2 in
                guard let location1 = user1.locationAsCLLocation(),
                      let location2 = user2.locationAsCLLocation() else {
                    return false
                }
                let distance1 = currentLocation.distance(from: location1)
                let distance2 = currentLocation.distance(from: location2)
                return distance1 < distance2
            }
            .prefix(5)
            .map { Runner(user: $0) }
    }
    
    private func isLocationRecent(user: UserApp) -> Bool {
        guard let lastUpdate = user.lastLocationUpdate else { return false }
        let hourAgo = Date().addingTimeInterval(-3600) // 1 hour ago
        return lastUpdate > hourAgo
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Greeting Text
                    HStack {
                        Text(NSLocalizedString("Hello", comment: "") + ",")
                            .font(.title2)
                        
                        Text(userName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Search Bar Button
                    Button(action: { isSearchActive = true }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            Text(NSLocalizedString("Search runners, communities...", comment: ""))
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Updated Interests Section
                    InterestsTabView(
                        interests: $interests,
                        followedInterests: $followedInterests
                    )
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        // Create Run Button
                        NavigationLink(destination: CreateRunView(selectedSegment: $selectedSegment, selectedTab: $selectedTab).navigationBarBackButtonHidden(true)) {
                            ActionButton(
                                title: NSLocalizedString("Create Run", comment: ""),
                                icon: "plus.circle.fill",
                                backgroundColor: .black
                            )
                        }
                        
                        // Join Run Button
                        Button(action: {
                            selectedTab = 2
                        }) {
                            ActionButton(
                                title: NSLocalizedString("Join Run", comment: ""),
                                icon: "person.2.fill",
                                backgroundColor: .white,
                                isOutlined: true
                            )
                        }
                       
                    }
                    .padding(.horizontal)
                    
                    // Updated Runners Section
                    VStack(alignment: .leading) {
                        HStack {
                            Text(NSLocalizedString("Runners Nearby", comment: ""))
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button(action: {
                                showingAllRunners = true
                            }) {
                                Text(NSLocalizedString("See All", comment: ""))
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .padding(.horizontal)
                        
                        if nearbyRunners.isEmpty {
                            EmptyStateView(
                                message: "No runners found",
                                systemImage: "figure.run",
                                description: "There are no runners in your area yet"
                            )
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 12) {
                                    ForEach(nearbyRunners.prefix(5)) { runner in
                                        NavigationLink(destination: RunnerDetailView(runner: runner)) {
                                            runnerCard(for: runner)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .sheet(isPresented: $showingAllRunners) {
                        NavigationView {
                            AllRunnersView(runners: nearbyRunners, users: users, locationManager: locationManager)
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingNotifications = true }) {
                        ZStack {
                            Image(systemName: "bell.fill")
                            
                            if notificationManager.unreadNotifications > 0 {
                                Text("\(notificationManager.unreadNotifications)")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 10, y: -10)
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        AsyncImage(url: URL(string: profileImageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(Text("👤").font(.system(size: 16)))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
            }
            .sheet(isPresented: $isSearchActive) {
                SearchView()
            }
            .onAppear {
                locationManager.requestLocation()
                Task {
                    await fetchUserProfile()
                    await fetchUsers()
                    await fetchInterests()
                }
                notificationManager.fetchNotifications()
            }
            .refreshable {
                Task {
                    await fetchUsers()
                }
            }
        }
    }
    
    private func fetchUsers() async {
        let db = Firestore.firestore()
        
        do {
            let snapshot = try await db.collection("users").getDocuments()
            self.users = snapshot.documents.compactMap { document in
                UserApp(id: document.documentID, data: document.data())
            }
            print("Fetched \(self.users.count) users")
        } catch {
            print("Error fetching users (HomeView): \(error.localizedDescription)")
        }
    }
    
    private func fetchInterests() async {
        let db = Firestore.firestore()
        
        do {
            let querySnapshot = try await db.collection("interests").order(by: "name").getDocuments()
            await MainActor.run {
                self.interests = querySnapshot.documents.map { document in
                    let interest = Interest(id: document.documentID, data: document.data())
                    print("Fetched interest: \(interest.name)")
                    return interest
                }
                self.interests.shuffle()
                print("✅ Interests loaded: \(self.interests.count)")
            }
        } catch {
            print("❌ Error fetching interests: \(error.localizedDescription)")
        }
    }
    
    private func fetchUserProfile() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if document.exists {
                if let name = document.data()?["name"] as? String {
                    self.userName = name.components(separatedBy: " ").first ?? name
                }
                if let imageUrl = document.data()?["profileImageUrl"] as? String {
                    self.profileImageUrl = imageUrl
                }
            }
        } catch {
            print("Error fetching user info: \(error.localizedDescription)")
        }
    }
    
    // Helper function for consistent runner card design
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
            
            // Add active status indicator
            Circle()
                .fill(runner.isActive ? Color.green : Color.gray)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .position(x: 12, y: 12)
        }
        .frame(width: 120, height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

