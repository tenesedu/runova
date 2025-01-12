import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import FirebaseStorage

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentTab = 0
    @State private var age: String = ""
    @State private var gender = ""
    @State private var city = ""
    @State private var profileImageUrl: String = ""
    @State private var goals: [String] = []
    @State private var interests: [String] = []
    @State private var locationEnabled = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToMain = false
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var isUploading = false
    @State private var selectedAge: Int = 18 // Default age
    
    let genderOptions = ["Male", "Female", "Other", "Prefer not to say"]
    let availableInterests = ["Trail Running", "Ultra Running", "Marathon", "10km Runs", "5km Runs", "Social Running", "Fun Running", "Sprinting", "Track Running", "Networking"]
    let maxGoals = 3
    
    var body: some View {
        NavigationStack {
            TabView(selection: $currentTab) {
                // Age Selection
                onboardingPage {
                    Text("How old are you?")
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.top, 50)
                    
                    Spacer()
                    
                    // Age Picker
                    Picker("Select Age", selection: $selectedAge) {
                        ForEach(0..<101) { age in // Age range from 0 to 100
                            Text("\(age)").tag(age)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 150) // Adjust height for better visibility
                    
                    Spacer()
                    
                    nextButton(tabIndex: 0)
                }
                .tag(0)
                
                // Gender
                onboardingPage {
                    Text("What's your\ngender?")
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.top, 50)
                    
                    Spacer()
                    
                    Picker("", selection: $gender) {
                        Text("Select Gender").tag("")
                        ForEach(genderOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .gray.opacity(0.2), radius: 10)
                    )
                    
                    Spacer()
                    
                    nextButton(tabIndex: 1)
                }
                .tag(1)
                
                // City
                onboardingPage {
                    Text("Where do you\nlive?")
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.top, 50)
                    
                    Spacer()
                    
                    TextField("Enter your city", text: $city)
                        .font(.title3)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .gray.opacity(0.2), radius: 10)
                        )
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    nextButton(tabIndex: 2)
                }
                .tag(2)
                
                // Profile Image
                onboardingPage {
                    Text("Upload your\nProfile Image")
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.top, 50)
                    
                    Spacer()
                    
                    Button(action: {
                        isImagePickerPresented = true
                    }) {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, lineWidth: 4))
                        } else {
                            Text("Select Image")
                                .font(.title3)
                                .padding()
                                .frame(width: 150, height: 150)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    .sheet(isPresented: $isImagePickerPresented) {
                        ImagePicker(image: $selectedImage)
                    }
                    
                    Spacer()
                    
                    nextButton(tabIndex: 3)
                }
                .tag(3)
                
                // Goals
                onboardingPage {
                    Text("What are your\nfitness goals? (Select up to \(maxGoals))")
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.top, 50)
                    
                    Spacer()
                    
                    ForEach(0..<maxGoals, id: \.self) { index in
                        HStack {
                            TextField("Goal \(index + 1)", text: Binding(
                                get: { goals.indices.contains(index) ? goals[index] : "" },
                                set: { newValue in
                                    if goals.indices.contains(index) {
                                        goals[index] = newValue
                                    } else if !newValue.isEmpty {
                                        goals.append(newValue)
                                    }
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .gray.opacity(0.2), radius: 10)
                            )
                        }
                    }
                    
                    Spacer()
                    
                    nextButton(tabIndex: 4)
                }
                .tag(4)
                
                // Interests
                onboardingPage {
                    Text("What are your\ninterests? (Select up to 5)")
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.top, 50)
                    
                    Spacer()
                    
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(availableInterests, id: \.self) { interest in
                            Button(action: {
                                if interests.contains(interest) {
                                    interests.removeAll { $0 == interest }
                                } else if interests.count < 5 {
                                    interests.append(interest)
                                }
                            }) {
                                Text(interest)
                                    .padding()
                                    .background(interests.contains(interest) ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(interests.contains(interest) ? .white : .black)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    nextButton(tabIndex: 5)
                }
                .tag(5)
                
                // Location Permission
                onboardingPage {
                    Text("Enable\nLocation?")
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                        .padding(.top, 50)
                    
                    Text("This helps us show you nearby running routes and connect with runners in your area.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                    
                    Spacer()
                    
                    Toggle("", isOn: $locationEnabled)
                        .labelsHidden()
                        .scaleEffect(1.5)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .gray.opacity(0.2), radius: 10)
                        )
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    completeButton
                }
                .tag(6)
            }
            .background(Color(.systemGroupedBackground))
            .tabViewStyle(.page(indexDisplayMode: .never))
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), 
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }
            .navigationDestination(isPresented: $navigateToMain) {
                MainTabView()
                    .navigationBarBackButtonHidden()
            }
        }
    }
    
    @ViewBuilder
    private func onboardingPage<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack {
            content()
        }
        .padding(.bottom, 50)
    }
    
    private var completeButton: some View {
        Button(action: completeOnboarding) {
            Text("Complete Setup")
                .font(.title3.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue)
                        .shadow(color: .blue.opacity(0.3), radius: 10)
                )
                .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func nextButton(tabIndex: Int) -> some View {
        Button(action: {
            withAnimation {
                currentTab = tabIndex + 1
            }
        }) {
            Text("Next")
                .font(.title3.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue)
                        .shadow(color: .blue.opacity(0.3), radius: 10)
                )
                .padding(.horizontal)
        }
    }
    
    private func handleImageSelection(_ image: UIImage?) {
        guard let image = image else { return }
        selectedImage = image
    }
    
    private func completeOnboarding() {
        isUploading = true
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user ID found")
            return
        }
        
        // If an image was selected, upload it first
        if let image = selectedImage {
            StorageManager.shared.uploadProfileImage(image, userId: userId) { imageUrl in
                saveUserProfile(imageUrl: imageUrl)
            }
        } else {
            // No image selected, proceed with nil image URL
            saveUserProfile(imageUrl: nil)
        }
    }
    
    private func saveUserProfile(imageUrl: String?) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "age": age,
            "gender": gender,
            "city": city,
            "profileImageUrl": imageUrl ?? "",
            "goals": goals,
            "interests": interests,
            "locationEnabled": locationEnabled,
            "onboardingCompleted": true,
            "createdAt": Date()
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            isUploading = false
            
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
                return
            }
            
            // Complete onboarding
            withAnimation {
                navigateToMain = true
            }
        }
    }
    
    private func requestLocationPermission() {
        // Request location permission
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
    }
}

// ImagePicker for selecting images
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            if let result = results.first {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                        DispatchQueue.main.async {
                            self.parent.image = image as? UIImage
                        }
                    }
                }
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
} 
