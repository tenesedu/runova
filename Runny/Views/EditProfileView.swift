import SwiftUI
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    // User data
    var userName: String
    var gender: String
    var city: String
    var age: String
    var goals: [String]
    var interests: [String]
    var profileImage: UIImage?
    
    // Edited states
    @State private var editedUserName: String = ""
    @State private var editedGender: String = ""
    @State private var editedCity: String = ""
    @State private var editedAge: Int = 18
    @State private var editedGoals: [String] = []
    @State private var editedInterests: [String] = []
    @State private var editedPaceMinutes: Int = 5
    @State private var editedPaceSeconds: Int = 0
    @State private var newProfileImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var alertMessage: String = ""
    @State private var showAlert = false
    
    let availableInterests = ["Trail Running", "Ultra Running", "Marathon", "10km Runs", "5km Runs", "Social Running", "Fun Running", "Sprinting", "Track Running", "Networking"]
    let genderOptions = ["Male", "Female", "Other", "Prefer not to say"]
    let ageRange = Array(13...100)
    let minutesRange = Array(3...15)
    let secondsRange = Array(0...59)
    let availableGoals = ["Weight Loss", "Improve Speed", "Build Endurance", "Social Running", "Marathon Training", "Stay Active", "Race Preparation"]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Profile Image
                    HStack {
                        Spacer()
                        Button(action: {
                            isImagePickerPresented = true
                        }) {
                            if let image = newProfileImage ?? profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section {
                    TextField("Name", text: $editedUserName)
                        .font(.system(size: 16))
                    
                    TextField("City", text: $editedCity)
                        .font(.system(size: 16))
                    
                    // Age Picker
                    HStack {
                        Text("Age")
                            .foregroundColor(.gray)
                        Spacer()
                        Picker("", selection: $editedAge) {
                            ForEach(ageRange, id: \.self) { age in
                                Text("\(age)")
                                    .font(.system(size: 14))
                                    .tag(age)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 45)
                        .clipped()
                    }
                    
                    // Gender Selection
                    HStack {
                        Text("Gender")
                            .foregroundColor(.gray)
                        Spacer()
                        Menu {
                            ForEach(genderOptions, id: \.self) { option in
                                Button(action: {
                                    editedGender = option
                                }) {
                                    HStack {
                                        Text(option)
                                        if editedGender == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(editedGender.isEmpty ? "Select" : editedGender)
                                    .foregroundColor(editedGender.isEmpty ? .gray : .black)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // Average Pace
                    HStack {
                        Text("Average Pace")
                            .foregroundColor(.gray)
                        Spacer()
                        HStack(spacing: 0) {
                            Picker("", selection: $editedPaceMinutes) {
                                ForEach(minutesRange, id: \.self) { minute in
                                    Text("\(minute)")
                                        .font(.system(size: 14))
                                        .tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 35)
                            .clipped()
                            
                            Text(":")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 1)
                            
                            Picker("", selection: $editedPaceSeconds) {
                                ForEach(secondsRange, id: \.self) { second in
                                    Text(String(format: "%02d", second))
                                        .font(.system(size: 14))
                                        .tag(second)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 35)
                            .clipped()
                        }
                    }
                }
                
                Section(header: Text("Interests").foregroundColor(.gray)) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableInterests, id: \.self) { interest in
                                InterestToggle(
                                    interest: interest,
                                    isSelected: editedInterests.contains(interest),
                                    action: { toggleInterest(interest) }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets())
                }
                
                Section(header: Text("Goals").foregroundColor(.gray)) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableGoals, id: \.self) { goal in
                                InterestToggle(
                                    interest: goal,
                                    isSelected: editedGoals.contains(goal),
                                    action: { toggleGoal(goal) }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .foregroundColor(.black)
                }
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(image: $newProfileImage)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                editedUserName = userName
                editedGender = gender
                editedCity = city
                editedAge = Int(age) ?? 18
                editedGoals = goals
                editedInterests = interests
            }
            .tint(.black)
        }
    }
    
    private func toggleInterest(_ interest: String) {
        if editedInterests.contains(interest) {
            editedInterests.removeAll { $0 == interest }
        } else {
            editedInterests.append(interest)
        }
    }
    
    private func toggleGoal(_ goal: String) {
        if editedGoals.contains(goal) {
            editedGoals.removeAll { $0 == goal }
        } else {
            editedGoals.append(goal)
        }
    }
    
    private func saveProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Create user data dictionary
        var userData: [String: Any] = [
            "name": editedUserName,
            "gender": editedGender,
            "city": editedCity,
            "age": String(editedAge),
            "averagePace": "\(editedPaceMinutes):\(String(format: "%02d", editedPaceSeconds))",
            "interests": editedInterests,
            "goals": editedGoals
        ]
        
        // Handle profile image upload if there's a new image
        if let newImage = newProfileImage {
            let storage = Storage.storage()
            let storageRef = storage.reference().child("profile_images/\(userId).jpg")
            
            guard let imageData = newImage.jpegData(compressionQuality: 0.8) else {
                alertMessage = "Error preparing image"
                showAlert = true
                return
            }
            
            // Show loading state if needed
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            storageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    alertMessage = "Error uploading image: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                // Get download URL
                storageRef.downloadURL { url, error in
                    if let error = error {
                        alertMessage = "Error getting download URL: \(error.localizedDescription)"
                        showAlert = true
                        return
                    }
                    
                    if let downloadURL = url {
                        userData["profileImageUrl"] = downloadURL.absoluteString
                        
                        // Save all user data
                        saveUserData(userId: userId, userData: userData)
                    }
                }
            }
        } else {
            // Save user data without updating the image
            saveUserData(userId: userId, userData: userData)
        }
    }
    
    private func saveUserData(userId: String, userData: [String: Any]) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData(userData) { error in
            if let error = error {
                alertMessage = "Error saving profile: \(error.localizedDescription)"
                showAlert = true
            } else {
                dismiss() // Dismiss the view after successful save
            }
        }
    }
}

struct InterestToggle: View {
    let interest: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(interest)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.black : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(isSelected ? .white : .black)
        }
    }
} 
