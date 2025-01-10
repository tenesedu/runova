import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @State private var runners: [Runner] = []
    @State private var interests: [Interest] = []
    @State private var isLoading = true
    @State private var showingProfile = false
    @State private var showingAllRunners = false
    @State private var userName: String = ""
    @State private var profileImageUrl: String = ""
    @State private var searchText: String = ""
    
    var filteredRunners: [Runner] {
        if searchText.isEmpty {
            return runners
        }
        return runners.filter { runner in
            runner.name.localizedCaseInsensitiveContains(searchText) ||
            runner.city.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredInterests: [Interest] {
        if searchText.isEmpty {
            return interests
        }
        return interests.filter { interest in
            interest.name.localizedCaseInsensitiveContains(searchText)
        }
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
                        
                        // Join Run Button
                        NavigationLink(destination: RunsView()) {
                            ActionButton(
                                title: "Join Run".localized,
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
                            Text("Runners Near You".localized)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button(action: {
                                showingAllRunners = true
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                    .padding(8)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding(.horizontal)
                        
                        if filteredRunners.isEmpty {
                            EmptyStateView(
                                message: searchText.isEmpty ? "No runners found" : "No results found",
                                systemImage: "figure.run",
                                description: searchText.isEmpty ? "There are no runners in your area yet" : "Try adjusting your search"
                            )
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 12) {
                                    ForEach(filteredRunners.prefix(4)) { runner in
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
                            RunnersView(runners: runners)
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
                fetchUserName()
                fetchRunners()
                fetchInterests()
                fetchProfileImage()
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
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching runners: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found")
                return 
            }
            
            self.runners = documents.compactMap { document -> Runner? in
                let data = document.data()
                
                // Skip the current user
                if document.documentID == Auth.auth().currentUser?.uid {
                    return nil
                }
                
                let name = data["name"] as? String ?? "Unknown"
                let age = data["age"] as? String ?? "N/A"
                let averagePace = data["averagePace"] as? String ?? "N/A"
                let city = data["city"] as? String ?? "Unknown"
                let profileImageUrl = data["profileImageUrl"] as? String ?? ""
                
                return Runner(
                    id: document.documentID,
                    name: name,
                    age: age,
                    averagePace: averagePace,
                    city: city,
                    profileImageUrl: profileImageUrl,
                    gender: data["gender"] as? String ?? "Not specified"
                )
            }
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
    
    private func fetchUserName() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                if let name = document.data()?["name"] as? String {
                    self.userName = name.components(separatedBy: " ").first ?? name
                }
            }
        }
    }
    
    private func fetchProfileImage() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
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
            .frame(width: 120, height: 160) // Smaller size
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
        .frame(width: 120, height: 160) // Smaller size
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

struct Runner: Identifiable {
    let id: String
    let name: String
    let age: String
    let averagePace: String
    let city: String
    let profileImageUrl: String
    let gender: String
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
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            Group {
                if isOutlined {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 1.5)
                        .background(backgroundColor)
                } else {
                    backgroundColor
                }
            }
        )
        .foregroundColor(isOutlined ? .black : .white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(isOutlined ? 0.05 : 0.1),
                radius: isOutlined ? 4 : 8,
                x: 0,
                y: isOutlined ? 2 : 4)
    }
} 
