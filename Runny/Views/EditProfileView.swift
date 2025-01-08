import SwiftUI
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var userName: String
    var gender: String
    var city: String
    var age: String
    var goals: [String]
    var interests: [String]
    var profileImage: UIImage?
    
    @State private var editedUserName: String = ""
    @State private var editedGender: String = ""
    @State private var editedCity: String = ""
    @State private var editedAge: String = ""
    @State private var editedGoals: [String] = []
    @State private var editedInterests: [String] = []
    @State private var editedAveragePace: String = ""
    @State private var newProfileImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var alertMessage: String = ""
    @State private var showAlert = false
    
    let availableInterests = ["Trail Running", "Ultra Running", "Marathon", "10km Runs", "5km Runs", "Social Running", "Fun Running", "Sprinting", "Track Running", "Networking"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Image Editor
                    Button(action: {
                        isImagePickerPresented = true
                    }) {
                        if let image = newProfileImage ?? profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, lineWidth: 4))
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 30))
                                )
                        }
                    }
                    .padding()
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        TextField("Name", text: $editedUserName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("City", text: $editedCity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Age", text: $editedAge)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .gray.opacity(0.2), radius: 10)
                            )
                            .padding(.bottom, 20)
                        
                        TextField("Average Pace (min/km)", text: $editedAveragePace)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .gray.opacity(0.2), radius: 10)
                            )
                            .padding(.bottom, 20)
                        
                        Picker("Gender", selection: $editedGender) {
                            Text("Select Gender").tag("")
                            Text("Male").tag("Male")
                            Text("Female").tag("Female")
                            Text("Other").tag("Other")
                        }
                        
                        // Goals Editor
                        VStack(alignment: .leading) {
                            Text("Goals")
                                .font(.headline)
                            
                            ForEach(editedGoals.indices, id: \.self) { index in
                                HStack {
                                    TextField("Goal \(index + 1)", text: $editedGoals[index])
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    Button(action: {
                                        // Remove goal
                                        editedGoals.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            // Button to add a new goal
                            Button(action: {
                                if editedGoals.count < 5 { // Limit to 5 goals
                                    editedGoals.append("")
                                }
                            }) {
                                Text("Add Goal")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Interests Selector
                        VStack(alignment: .leading) {
                            Text("Interests")
                                .font(.headline)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                                ForEach(availableInterests, id: \.self) { interest in
                                    Button(action: {
                                        toggleInterest(interest)
                                    }) {
                                        Text(interest)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                editedInterests.contains(interest) ?
                                                Color.blue : Color.gray.opacity(0.2)
                                            )
                                            .foregroundColor(
                                                editedInterests.contains(interest) ?
                                                .white : .primary
                                            )
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(image: $newProfileImage)
            }
        }
        .onAppear {
            // Initialize edited values
            editedUserName = userName
            editedGender = gender
            editedCity = city
            editedAge = age
            editedGoals = goals
            editedInterests = interests
            editedAveragePace = ""
        }
    }
    
    private func toggleInterest(_ interest: String) {
        if editedInterests.contains(interest) {
            editedInterests.removeAll { $0 == interest }
        } else if editedInterests.count < 5 {
            editedInterests.append(interest)
        }
    }
    
    private func saveChanges() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        var data: [String: Any] = [
            "name": editedUserName,
            "gender": editedGender,
            "city": editedCity,
            "age": editedAge,
            "averagePace": editedAveragePace,
            "goals": editedGoals,
            "interests": editedInterests
        ]
        
        // If a new profile image is selected, upload it to Firebase Storage
        if let newProfileImage = newProfileImage {
            uploadProfileImage(image: newProfileImage) { imageUrl in
                data["profileImageUrl"] = imageUrl // Add the image URL to the data
                updateFirestore(userId: userId, data: data) // Update Firestore with the new data
            }
        } else {
            updateFirestore(userId: userId, data: data) // Update Firestore without a new image
        }
    }
    
    private func uploadProfileImage(image: UIImage, completion: @escaping (String?) -> Void) {
        // Convert the image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }
        
        // Create a reference to Firebase Storage
        let storage = Storage.storage()
        let storageRef = storage.reference().child("profile_images/\(UUID().uuidString).jpg")
        
        // Upload the image data
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            // Get the download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    completion(url?.absoluteString)
                }
            }
        }
    }
    
    private func updateFirestore(userId: String, data: [String: Any]) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData(data) { error in
            if let error = error {
                print("Error updating profile: \(error.localizedDescription)")
                alertMessage = "Error updating profile: \(error.localizedDescription)"
                showAlert = true
            } else {
                print("Profile updated successfully!")
                dismiss() // Dismiss the view after saving
            }
        }
    }
} 
