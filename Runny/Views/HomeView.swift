import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @State private var runners: [Runner] = []
    @State private var interests: [Interest] = []
    @State private var isLoading = true
    @State private var showingProfile = false
    @State private var showingAllRunners = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Interests Section
                    InterestCarousel(interests: interests)
                        .padding(.top)
                    
                    // Runners Section
                    VStack(alignment: .leading) {
                        Text("Runners Near You")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        if runners.isEmpty {
                            EmptyStateView(
                                message: "No runners found",
                                systemImage: "figure.run",
                                description: "There are no runners in your area yet"
                            )
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 15) {
                                    ForEach(runners) { runner in
                                        NavigationLink(destination: RunnerDetailView(runner: runner)) {
                                            RunnerCard(runner: runner)
                                                .frame(width: 300)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        Image(systemName: "person.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .onAppear {
                fetchRunners()
                fetchInterests()
            }
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
}

struct RunnerCard: View {
    let runner: Runner
    @State private var profileImage: UIImage?
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading) {
                // Profile Image
                ZStack {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .overlay(Text("👤").font(.system(size: 40)))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
                
                // Runner Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(runner.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text("\(runner.age) age")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("\(runner.averagePace) min/km")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .onAppear {
                if !runner.profileImageUrl.isEmpty {
                    loadProfileImage()
                }
            }
        }
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
