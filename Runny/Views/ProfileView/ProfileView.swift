import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var userName: String = ""
    @State private var profileImageUrl: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var gender: String = ""
    @State private var city: String = ""
    @State private var age: String = ""
    @State private var averagePace: String = ""
    @State private var goals: [String] = []
    @State private var interests: [String] = []
    @State private var isEditing = false
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    var userId: String? = nil // nil means current user
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Profile Image Section
                    ZStack {
                        Color.blue.opacity(0.1)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                        
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 10)
                        } else {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 120, height: 120)
                                .overlay(Text("👤").font(.system(size: 60)))
                                .shadow(radius: 10)
                        }
                    }
                    .padding(.bottom)
                    
                    // User Info Section
                    VStack(spacing: 20) {
                        Text(userName)
                            .font(.system(size: 28, weight: .bold))
                        
                        infoCard(title: "Personal Information") {
                            InfoRow(icon: "person.fill", title: "Gender", value: gender)
                            InfoRow(icon: "mappin.circle.fill", title: "City", value: city)
                            InfoRow(icon: "calendar", title: "Age", value: age)
                            InfoRow(icon: "clock", title: "Average Pace", value: averagePace)
                        }
                        
                        infoCard(title: "Goals") {
                            ForEach(goals, id: \.self) { goal in
                                InfoRow(icon: "target", title: "", value: goal)
                            }
                        }
                        
                        infoCard(title: "Interests") {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                                ForEach(interests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Logout Button at the bottom
                    Button(action: logout) {
                        Text("Logout")
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Language Selection Section
                    Section(header: Text("Language".localized)) {
                        HStack(spacing: 20) {
                            // English Flag Button
                            LanguageButton(
                                flag: "🇺🇸",
                                language: "English",
                                isSelected: selectedLanguage == "en"
                            ) {
                                selectedLanguage = "en"
                            }
                            
                            // Spanish Flag Button
                            LanguageButton(
                                flag: "🇪🇸",
                                language: "Español",
                                isSelected: selectedLanguage == "es"
                            ) {
                                selectedLanguage = "es"
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Profile".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: ConnectionsView()) {
                        Image(systemName: "person.2")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isEditing = true
                    }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ConnectionRequestsView()) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                EditProfileView(
                    userName: userName,
                    gender: gender,
                    city: city,
                    age: age,
                    goals: goals,
                    interests: interests,
                    profileImage: profileImage
                )
                .onDisappear {
                    fetchUserData()
                }
            }
            .onAppear {
                fetchUserData()
            }
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error logging out: \(error.localizedDescription)")
        }
    }
    
    private func infoCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            
            content()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                userName = data?["name"] as? String ?? "User"
                gender = data?["gender"] as? String ?? "Not specified"
                city = data?["city"] as? String ?? "Not specified"
                age = data?["age"] as? String ?? "Not specified"
                averagePace = data?["averagePace"] as? String ?? "Not specified"
                goals = data?["goals"] as? [String] ?? []
                interests = data?["interests"] as? [String] ?? []
                
                if let imageUrl = data?["profileImageUrl"] as? String {
                    loadProfileImage(from: imageUrl)
                }
            } else {
                print("Document does not exist: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func loadProfileImage(from url: String) {
        guard let url = URL(string: url) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            }
        }.resume()
    }
}

// New Language Button Component
struct LanguageButton: View {
    let flag: String
    let language: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(flag)
                    .font(.system(size: 40))
                
                Text(language)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .black : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.black : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.black.opacity(0.05) : Color.clear)
            )
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
} 
