import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct CreateGroupView: View {
    @Binding var isPresented: Bool
    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var selectedMembers: Set<String> = []
    @State private var connections: [Runner] = []
    @State private var isLoading = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var groupImage: UIImage?
    let onComplete: (String, Set<String>) -> Void
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Group Info")) {
                    // Group Image Picker
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedImage, matching: .images) {
                            if let groupImage = groupImage {
                                Image(uiImage: groupImage)
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
                                        VStack {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 30))
                                                .foregroundColor(.gray)
                                            Text("Add Photo")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    )
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    
                    TextField("Group Name", text: $groupName)
                    
                    TextField("Group Description", text: $groupDescription, axis: .vertical)
                        .lineLimit(3...6)
                       
                }
                
                Section(header: Text("Add Members")) {
                    ForEach(connections) { connection in
                        HStack {
                            AsyncImage(url: URL(string: connection.profileImageUrl)) { image in
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
                            
                            Text(connection.name)
                            
                            Spacer()
                            
                            if selectedMembers.contains(connection.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedMembers.contains(connection.id) {
                                selectedMembers.remove(connection.id)
                            } else {
                                selectedMembers.insert(connection.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Group")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Create") {
                    createGroup()
                }
                .disabled(groupName.isEmpty || selectedMembers.isEmpty || isLoading)
            )
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .onAppear {
                fetchConnections()
            }
            .onChange(of: selectedImage) { _ in
                Task {
                    if let data = try? await selectedImage?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            groupImage = uiImage
                        }
                    }
                }
            }
        }
    }
    
    private func createGroup() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        // First upload the image if selected
        if let groupImage = groupImage {
            uploadGroupImage(groupImage) { imageUrl in
                createGroupInFirestore(userId: userId, imageUrl: imageUrl)
            }
        } else {
            createGroupInFirestore(userId: userId, imageUrl: nil)
        }
    }
    
    private func uploadGroupImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(nil)
            return
        }
        
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("group_images/\(UUID().uuidString).jpg")
        
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            imageRef.downloadURL { url, error in
                completion(url?.absoluteString)
            }
        }
    }
    
    private func createGroupInFirestore(userId: String, imageUrl: String?) {
        var participants = selectedMembers
        participants.insert(userId)
        
        var groupData: [String: Any] = [
            "type": "group",
            "groupName": groupName,
            "groupDescription": groupDescription,
            "participants": Array(participants),
            "createdBy": userId,
            "createdAt": FieldValue.serverTimestamp(),
            "lastMessage": "",
            "lastMessageTime": FieldValue.serverTimestamp(),
            "unreadCount": participants.reduce(into: [String: Int]()) { dict, userId in
                dict[userId] = 0
            }
        ]
        
        if let imageUrl = imageUrl {
            groupData["groupImageUrl"] = imageUrl
        }
        
        let db = Firestore.firestore()
        db.collection("conversations").addDocument(data: groupData) { error in
            isLoading = false
            if let error = error {
                print("Error creating group: \(error.localizedDescription)")
            } else {
                onComplete(groupName, selectedMembers)
                isPresented = false
            }
        }
    }
    
    private func fetchConnections() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let document = snapshot,
                  let connectionIds = document.data()?["connections"] as? [String] else {
                return
            }
            
            connections.removeAll()
            
            for connectionId in connectionIds {
                db.collection("users").document(connectionId).getDocument { snapshot, error in
                    if let document = snapshot,
                       let data = document.data() {
                        let user = User(id: document.documentID, data: data)
                        let runner = Runner(user: user)
                        
                        DispatchQueue.main.async {
                            connections.append(runner)
                        }
                    }
                }
            }
        }
    }
}


