import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var selectedFriends: Set<String> = []
    @State private var friends: [Runner] = []
    @State private var isLoading = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var groupImage: UIImage?
    var onComplete: (String, Set<String>) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Group Info")) {
                    // Group Image Picker
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedImage) {
                            if let groupImage = groupImage {
                                Image(uiImage: groupImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
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
                    .padding(.vertical)
                    
                    TextField("Group Name", text: $groupName)
                    TextField("Description (Optional)", text: $groupDescription)
                }
                
                Section(header: Text("Select Friends")) {
                    if friends.isEmpty {
                        Text("No friends to add")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(friends) { friend in
                            FriendSelectionRow(
                                friend: friend,
                                isSelected: selectedFriends.contains(friend.id),
                                onToggle: { isSelected in
                                    if isSelected {
                                        selectedFriends.insert(friend.id)
                                    } else {
                                        selectedFriends.remove(friend.id)
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(groupName.isEmpty || selectedFriends.isEmpty || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .onAppear {
                fetchFriends()
            }
            .onChange(of: selectedImage) { _ in
                Task {
                    if let data = try? await selectedImage?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        groupImage = image
                    }
                }
            }
        }
    }
    
    private func fetchFriends() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(currentUserId).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let friendIds = data["friends"] as? [String] {
                
                // Fetch each friend's details
                for friendId in friendIds {
                    db.collection("users").document(friendId).getDocument { snapshot, error in
                        if let userData = snapshot?.data() {
                            let user = UserApp(id: snapshot?.documentID ?? "", data: userData)
                            let friend = Runner(user: user)
                            DispatchQueue.main.async {
                                if !friends.contains(where: { $0.id == friend.id }) {
                                    friends.append(friend)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func createGroup() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        let groupData: [String: Any] = [
            "type": "group",  // Make sure this is set
            "groupName": groupName,
            "groupDescription": groupDescription,
            "groupImageUrl": "",  // Will be updated after image upload
            "participants": Array(selectedFriends),
            "adminId": currentUserId,
            "createdBy": currentUserId,
            "createdAt": FieldValue.serverTimestamp(),
            "lastMessage": "",
            "lastMessageTime": FieldValue.serverTimestamp(),
            "unreadCount": [:]
        ]
        
        print("Creating group with data: \(groupData)")
        
        if let groupImage = groupImage {
            // Upload image first
            uploadGroupImage(groupImage) { imageUrl in
                createGroupInFirestore(userId: currentUserId, imageUrl: imageUrl)
            }
        } else {
            // Create group without image
            createGroupInFirestore(userId: currentUserId, imageUrl: nil)
        }
    }
    
    private func uploadGroupImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(nil)
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child("group_images/\(UUID().uuidString).jpg")
        
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if error != nil {
                completion(nil)
            } else {
                imageRef.downloadURL { url, error in
                    completion(url?.absoluteString)
                }
            }
        }
    }
    
    private func createGroupInFirestore(userId: String, imageUrl: String?) {
        let groupData: [String: Any] = [
            "type": "group",
            "name": groupName,
            "description": groupDescription,
            "imageUrl": imageUrl ?? "",
            "participants": Array(selectedFriends) + [userId],
            "adminId": userId,
            "createdBy": userId,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "lastMessage": "",
            "lastMessageTime": FieldValue.serverTimestamp(),
            "unreadCount": [:]
        ]
        
        let db = Firestore.firestore()
        db.collection("conversations").addDocument(data: groupData) { error in
            isLoading = false
            
            if let error = error {
                print("Error creating group: \(error.localizedDescription)")
            } else {
                onComplete(groupName, Set(selectedFriends))
                dismiss()
            }
        }
    }
}

struct FriendSelectionRow: View {
    let friend: Runner
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: { onToggle(!isSelected) }) {
            HStack {
                AsyncImage(url: URL(string: friend.profileImageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(Text("👤"))
                }
                
                Text(friend.name)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}


