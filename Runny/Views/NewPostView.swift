import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct NewPostView: View {
    let interests: [Interest]
    let selectedInterest: Interest?
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedInterestId: String
    
    init(interests: [Interest], selectedInterest: Interest? = nil) {
        self.interests = interests
        self.selectedInterest = selectedInterest
        self._selectedInterestId = State(initialValue: selectedInterest?.id ?? interests.first?.id ?? "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Post Details")) {
                TextField("Title", text: $title)
                TextEditor(text: $content)
                    .frame(height: 100)
                
                if let selectedInterest = selectedInterest {
                    Text("Posting in: \(selectedInterest.name)")
                        .foregroundColor(.secondary)
                } else {
                    Picker("Interest", selection: $selectedInterestId) {
                        ForEach(interests) { interest in
                            Text(interest.name).tag(interest.id)
                        }
                    }
                }
            }
            
            Button(action: createPost) {
                Text("Post")
            }
            .disabled(title.isEmpty || content.isEmpty)
        }
        .navigationTitle("New Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    private func createPost() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let currentInterest = selectedInterest ?? interests.first(where: { $0.id == selectedInterestId })
        guard let interest = currentInterest else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            guard let document = document,
                  let userName = document.data()?["name"] as? String,
                  let userProfileUrl = document.data()?["profileImageUrl"] as? String
            else { return }
            
            let postData: [String: Any] = [
                "userId": userId,
                "userName": userName,
                "userProfileUrl": userProfileUrl,
                "title": title,
                "content": content,
                "interest": interest.name,
                "interestColor": interest.color.toHex() ?? "#007AFF",
                "timestamp": FieldValue.serverTimestamp(),
                "likes": 0,
                "comments": 0
            ]
            
            db.collection("posts").addDocument(data: postData) { error in
                if let error = error {
                    print("Error creating post: \(error.localizedDescription)")
                } else {
                    dismiss()
                }
            }
        }
    }
} 
