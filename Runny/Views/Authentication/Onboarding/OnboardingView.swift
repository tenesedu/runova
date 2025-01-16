import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import FirebaseStorage

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var age: String = ""
    @Published var gender: String = ""
    @Published var city: String = ""
    @Published var profileImageUrl: String = ""
    @Published var goals: [String] = []
    @Published var interests: [String] = []
    @Published var locationEnabled: Bool = false
    @Published var isUploading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    func completeOnboarding(selectedImage: UIImage?) {
        guard let userId = Auth.auth().currentUser?.uid else {
            alertMessage = "No user ID found"
            showAlert = true
            return
        }

        isUploading = true

        if let image = selectedImage {
            UserService.shared.uploadProfileImage(image, userId: userId) { [weak self] imageUrl in
                self?.saveUserProfile(userId: userId, imageUrl: imageUrl)
            }
        } else {
            saveUserProfile(userId: userId, imageUrl: nil)
        }
    }

    private func saveUserProfile(userId: String, imageUrl: String?) {
        let userData: [String: Any] = [
            "name": name,
            "age": age,
            "gender": gender,
            "city": city,
            "profileImageUrl": imageUrl ?? "",
            "goals": goals,
            "interests": interests,
            "locationEnabled": locationEnabled,
            "onboardingCompleted": true,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        UserService.shared.saveUserData(userId: userId, data: userData) { [weak self] error in
            self?.isUploading = false
            
            if let error = error {
                self?.alertMessage = "Error saving user data: \(error.localizedDescription)"
                self?.showAlert = true
                return
            }
        }
    }
}

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var currentTab = 0
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var selectedAge = 18
    
    let genderOptions = ["Male", "Female", "Other", "Prefer not to say"]
    let availableInterests = ["Trail Running", "Ultra Running", "Marathon", "10km Runs", "5km Runs", "Social Running", "Fun Running", "Sprinting", "Track Running", "Networking"]
    let maxGoals = 3
    
    var body: some View {
        NavigationStack {
            mainContent
        }
    }
    
    private var mainContent: some View {
        TabView(selection: $currentTab) {
            nameInputPage
            ageSelectionPage
            genderSelectionPage
            cityInputPage
            profileImagePage
            goalsInputPage
            interestsSelectionPage
            locationPermissionPage
        }
        .background(Color(.systemGroupedBackground))
        .tabViewStyle(.page(indexDisplayMode: .never))
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                navigationButtons
            }
        }
    }
    
    private var navigationButtons: some View {
        Group {
            if currentTab < 7 {
                Button("Next") {
                    if currentTab == 0 && viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        viewModel.alertMessage = "Please enter your name"
                        viewModel.showAlert = true
                        return
                    }
                    withAnimation {
                        currentTab += 1
                    }
                }
            } else {
                Button("Complete") {
                    viewModel.age = "\(selectedAge)"
                    viewModel.completeOnboarding(selectedImage: selectedImage)
                }
                .disabled(viewModel.isUploading)
            }
        }
    }
    
    private var nameInputPage: some View {
        OnboardingPage(title: "What's your\nname?") {
            VStack(spacing: 20) {
                TextField("Enter your name", text: $viewModel.name)
                    .font(.title3)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .gray.opacity(0.2), radius: 10)
                    )
                    .padding(.horizontal)
                    .textInputAutocapitalization(.words)
                
                Text("This is how other runners will see you")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .tag(0)
    }
    
    private var ageSelectionPage: some View {
        OnboardingPage(title: "How old are you?") {
            Picker("Select Age", selection: $selectedAge) {
                ForEach(0..<101) { age in
                    Text("\(age)").tag(age)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 150)
        }
        .tag(1)
    }
    
    private var genderSelectionPage: some View {
        OnboardingPage(title: "What's your\ngender?") {
            Picker("", selection: $viewModel.gender) {
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
        }
        .tag(2)
    }
    
    private var cityInputPage: some View {
        OnboardingPage(title: "Where do you\nlive?") {
            TextField("Enter your city", text: $viewModel.city)
                .font(.title3)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .gray.opacity(0.2), radius: 10)
                )
                .padding(.horizontal)
        }
        .tag(3)
    }
    
    private var profileImagePage: some View {
        OnboardingPage(title: "Upload your\nProfile Image") {
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
        }
        .tag(4)
    }
    
    private var goalsInputPage: some View {
        OnboardingPage(title: "What are your\nfitness goals? (Select up to \(maxGoals))") {
            ForEach(0..<maxGoals, id: \.self) { index in
                TextField("Goal \(index + 1)", text: Binding(
                    get: { viewModel.goals.indices.contains(index) ? viewModel.goals[index] : "" },
                    set: { newValue in
                        if viewModel.goals.indices.contains(index) {
                            viewModel.goals[index] = newValue
                        } else if !newValue.isEmpty {
                            viewModel.goals.append(newValue)
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
        .tag(5)
    }
    
    private var interestsSelectionPage: some View {
        OnboardingPage(title: "What are your\ninterests? (Select up to 5)") {
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ],
                    spacing: 10
                ) {
                    ForEach(availableInterests, id: \.self) { interest in
                        Button(action: {
                            if viewModel.interests.contains(interest) {
                                viewModel.interests.removeAll { $0 == interest }
                            } else if viewModel.interests.count < 5 {
                                viewModel.interests.append(interest)
                            }
                        }) {
                            Text(interest)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(viewModel.interests.contains(interest) ? Color.blue : Color.gray.opacity(0.2))
                                )
                                .foregroundColor(viewModel.interests.contains(interest) ? .white : .black)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .tag(6)
    }
    
    private var locationPermissionPage: some View {
        OnboardingPage(title: "Enable\nLocation?") {
            VStack(spacing: 20) {
                Text("This helps us show you nearby running routes and connect with runners in your area.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                
                Toggle("Enable Location", isOn: $viewModel.locationEnabled)
                    .labelsHidden()
                    .scaleEffect(1.5)
                    .padding()
                    .frame(width: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .gray.opacity(0.2), radius: 10)
                    )
            }
            .padding(.horizontal)
        }
        .tag(7)
    }
}

// Reusable Onboarding Page Component
struct OnboardingPage<Content: View>: View {
    let title: String
    let content: () -> Content

    var body: some View {
        VStack {
            Text(title)
                .font(.system(size: 36, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.top, 50)

            Spacer()

            content()

            Spacer()
        }
        .padding(.bottom, 50)
    }
}

// Image Picker for Profile Image
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
