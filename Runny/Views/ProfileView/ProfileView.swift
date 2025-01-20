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
        ScrollView {
            VStack(spacing: 25) {
                // Profile Image Section
                ZStack {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 300)                                
                            
                            .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                            .overlay(
                            Text(userName)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .padding(),
                            alignment: .bottomLeading
                        )
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
                
                VStack {
                    Spacer() // This will push the settings button to the bottom
                    
                    NavigationLink(destination: ProfileSettingsView()) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.gray)
                            
                            Text("Settings")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .navigationTitle("Profile".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Home")
                            .font(.system(size: 16, weight: .regular))
                    }
                    .foregroundColor(.blue)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
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
