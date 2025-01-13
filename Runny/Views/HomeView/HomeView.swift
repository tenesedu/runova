import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

struct HomeView: View {
    @State private var users: [User] = []
    @State private var interests: [Interest] = []
    @State private var isLoading = true
    @State private var showingProfile = false
    @State private var showingAllRunners = false
    @State private var userName: String = ""
    @State private var profileImageUrl: String = ""
    @State private var searchText: String = ""
    @StateObject private var locationManager = LocationManager()
    
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
            interest.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var nearbyRunners: [Runner] {
        guard let currentLocation = locationManager.location else { return [] }
        
        return users
            .filter { user in
                guard let userLocation = user.locationAsCLLocation(),
                      user.id != Auth.auth().currentUser?.uid else {
                    return false
                }
                
                let distance = currentLocation.distance(from: userLocation)
                let isRecent = isLocationRecent(user: user)
                
                return distance <= 25000 && isRecent // 25km radius and recent location
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
            .map { Runner(user: $0) }
    }
    
    private func isLocationRecent(user: User) -> Bool {
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
                        Text("Hello".localized + ",")
                            .font(.title2)
                        
                        Text(userName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Updated Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Explore...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    
                    // Updated Interests Section
                    InterestCarousel(interests: filteredInterests)
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        // Create Run Button
                        NavigationLink(destination: CreateView()) {
                            ActionButton(
                                title: "Create Run".localized,
                                icon: "plus.circle.fill",
                                backgroundColor: .black
                            )
                        }
                        
                        // // Join Run Button
                        // NavigationLink(destination: RunsView()) {
                        //     ActionButton(
                        //         title: "Join Run".localized,
                        //         icon: "person.2.fill",
                        //         backgroundColor: .white,
                        //         isOutlined: true
                        //     )
                        // }
                    }
                    .padding(.horizontal)
                    
                    // Updated Runners Section
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Runners Near You".localized)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button(action: {
                                showingAllRunners = true
                            }) {
                                Text("See All")
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
                            AllRunnersView(runners: nearbyRunners, users: users)
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        AsyncImage(url: URL(string: profileImageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .onAppear {
                fetchUserInfo()
                fetchRunners()
                fetchInterests()
            }
            .refreshable {
                // Refresh all content
                await refreshContent()
            }
            .navigationBarItems(leading: Button(action: {
                // Action for notification button
                print("Notification button tapped")
            }) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.black)
            })
        }
    }
    
    private func fetchRunners() {
        let db = Firestore.firestore()
        let hourAgo = Date().addingTimeInterval(-3600)
        
        db.collection("users")
            .whereField("lastLocationUpdate", isGreaterThan: Timestamp(date: hourAgo))
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching users: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                self.users = documents.compactMap { document in
                    User(id: document.documentID, data: document.data())
                }
                
                print("Fetched \(self.users.count) users")
            }
    }
    
    private func fetchInterests() {
        print("🔍 Fetching interests...")
        let db = Firestore.firestore()
        db.collection("interests")
            .order(by: "name")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("❌ Error fetching interests: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("⚠️ No interest documents found")
                    return
                }
                
                print("📄 Found \(documents.count) interests")
                self.interests = documents.map { document in
                    let interest = Interest(id: document.documentID, data: document.data())
                    print("🏷 Interest: \(interest.name), Icon: \(interest.iconName)")
                    return interest
                }
                print("✅ Interests loaded: \(self.interests.count)")
            }
    }
    
    private func fetchUserInfo() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                if let name = document.data()?["name"] as? String {
                    self.userName = name.components(separatedBy: " ").first ?? name
                }
                if let imageUrl = document.data()?["profileImageUrl"] as? String {
                    self.profileImageUrl = imageUrl
                }
            }
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
        }
        .frame(width: 120, height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func refreshContent() async {
        // Use async/await to handle the refresh
        await withCheckedContinuation { continuation in
            isLoading = true
            
            // Fetch interests
            let db = Firestore.firestore()
            db.collection("interests")
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error refreshing interests: \(error.localizedDescription)")
                    } else if let documents = snapshot?.documents {
                        interests = documents.map { Interest(id: $0.documentID, data: $0.data()) }
                    }
                    
                    isLoading = false
                    continuation.resume()
                }
        }
    }
}

struct RunnerCard: View {
    let runner: Runner
    @State private var profileImage: UIImage?
    @State private var showingDetail = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Profile Image Section
                ZStack(alignment: .bottomLeading) {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(height: 100)
                            .overlay(
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50)
                                    .foregroundColor(.white.opacity(0.8))
                            )
                    }
                    
                    // Gradient Overlay
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .black.opacity(0.3)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                
                // Runner Info Section
                VStack(alignment: .leading, spacing: 12) {
                    // Name and Age
                    HStack {
                        Text(runner.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(runner.age)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Location and Stats
                    VStack(spacing: 8) {
                        // Location
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text(runner.city)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Pace
                        HStack {
                            Image(systemName: "speedometer")
                                .foregroundColor(.blue)
                            Text("\(runner.averagePace) min/km")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            }
            .frame(width: 160)
            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            NavigationView {
                RunnerDetailView(runner: runner)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingDetail = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            if !runner.profileImageUrl.isEmpty {
                loadProfileImage()
            }
        }
    }
    
    private func loadProfileImage() {
        guard let url = URL(string: runner.profileImageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            }
        }.resume()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    var isOutlined: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isOutlined ? .black : .white)
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isOutlined ? .black : .white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isOutlined ? backgroundColor : backgroundColor)
        )
        
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1),
                radius: 8,
                x: 0,
                y: 4)
    }
}

struct RunnerCardView: View {
    let runner: Runner
    let users: [User]
    @StateObject private var locationManager = LocationManager()
    
    private func calculateDistance() -> String? {
        guard let currentLocation = locationManager.location,
              let user = users.first(where: { $0.id == runner.id }),
              let userLocation = user.locationAsCLLocation() else {
            return nil
        }
        let distance = currentLocation.distance(from: userLocation)
        return String(format: "%.1f km", distance / 1000)
    }
    
    var body: some View {
        NavigationLink(destination: RunnerDetailView(runner: runner)) {
            VStack(alignment: .leading, spacing: 8) {
                // Profile Image
                AsyncImage(url: URL(string: runner.profileImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 160, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Runner Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(runner.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let distance = calculateDistance() {
                        Text(distance)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Text(runner.city)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 5)
            .frame(width: 160)
        }
    }
}

struct AllRunnersView: View {
    let runners: [Runner]
    let users: [User]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    
    var sortedRunners: [Runner] {
        guard let currentLocation = locationManager.location else { return runners }
        
        return users
            .filter { user in
                user.id != Auth.auth().currentUser?.uid
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
            .map { Runner(user: $0) }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sortedRunners) { runner in
                    NavigationLink(destination: RunnerDetailView(runner: runner)) {
                        HStack(spacing: 16) {
                            // Profile Image
                            AsyncImage(url: URL(string: runner.profileImageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(runner.name)
                                    .font(.headline)
                                
                                if let userLocation = users.first(where: { $0.id == runner.id })?.locationAsCLLocation(),
                                   let currentLocation = locationManager.location {
                                    Text(String(format: "%.1f km away", currentLocation.distance(from: userLocation) / 1000))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Text(runner.city)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("All Runners")
        .navigationBarItems(trailing: Button("Done") {
            dismiss()
        })
    }
}
