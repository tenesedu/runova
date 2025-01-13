// import SwiftUI
// import FirebaseFirestore
// import FirebaseAuth


// struct RunDetailView: View {
//     let run: Run
//     @Environment(\.dismiss) private var dismiss
//     @Environment(\.presentationMode) var presentationMode
//     @State private var creatorProfileUrl: String = ""
//     @State private var creatorName: String = ""
//     @State private var participants: [User] = []
//     @State private var pendingRequests: [User] = []
//     @State private var hasRequestedToJoin = false
//     @State private var showingAlert = false
//     @State private var alertMessage = ""
//     @State private var isLoading = false
//     @State private var showingEditSheet = false
//     @State private var showingDeleteAlert = false
//     @State private var showingActionSheet = false
    
//     private var isCreator: Bool {
//         run.createdBy == Auth.auth().currentUser?.uid
//     }
    
//     private var isParticipant: Bool {
//         guard let userId = Auth.auth().currentUser?.uid else { return false }
//         return run.currentParticipants.contains(userId)
//     }
    
//     var body: some View {
//         ScrollView {
//             VStack(alignment: .leading, spacing: 20) {
//                 // Creator Info
//                 HStack {
//                     AsyncImage(url: URL(string: creatorProfileUrl)) { image in
//                         image
//                             .resizable()
//                             .aspectRatio(contentMode: .fill)
//                     } placeholder: {
//                         Circle()
//                             .fill(Color.gray.opacity(0.3))
//                     }
//                     .frame(width: 50, height: 50)
//                     .clipShape(Circle())
                    
//                     VStack(alignment: .leading, spacing: 4) {
//                         Text(creatorName)
//                             .font(.system(size: 18, weight: .semibold))
//                         Text("Organizer")
//                             .font(.system(size: 14))
//                             .foregroundColor(.gray)
//                     }
//                     Spacer()
//                 }
//                 .padding(.horizontal)
                
//                 // Run Details
//                 VStack(alignment: .leading, spacing: 16) {
//                     Text(run.name)
//                         .font(.system(size: 24, weight: .bold))
                    
//                     if !run.description.isEmpty {
//                         Text(run.description)
//                             .font(.system(size: 16))
//                             .foregroundColor(.gray)
//                     }
                    
//                     // Location and Time
//                     VStack(alignment: .leading, spacing: 12) {
//                         HStack {
//                             Image(systemName: "location.fill")
//                             Text(run.location)
//                         }
//                         HStack {
//                             Image(systemName: "calendar")
//                             Text(formatDateTime(run.time))
//                         }
//                     }
//                     .foregroundColor(.gray)
                    
//                     // Stats Card
//                     HStack(spacing: 30) {
//                         StatItem(title: "Distance", value: "\(String(format: "%.1f", run.distance))km", icon: "figure.run")
//                         StatItem(title: "Pace", value: run.averagePace, icon: "stopwatch")
//                         if let terrain = run.terrain {
//                             StatItem(title: "Terrain", value: terrain, icon: "mountain.2")
//                         }
//                     }
//                     .padding()
//                     .background(Color.white)
//                     .cornerRadius(12)
//                     .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
//                 }
//                 .padding(.horizontal)
                
//                 // Participants Section
//                 VStack(alignment: .leading, spacing: 12) {
//                     Text("Participants (\(participants.count)/\(run.maxParticipants))")
//                         .font(.system(size: 18, weight: .semibold))
                    
//                     ScrollView(.horizontal, showsIndicators: false) {
//                         HStack(spacing: 12) {
//                             ForEach(participants) { participant in
//                                 ParticipantView(user: participant)
//                             }
//                         }
//                     }
//                 }
//                 .padding(.horizontal)
                
//                 // Pending Requests Section (Only visible to creator)
//                 if isCreator && !pendingRequests.isEmpty {
//                     VStack(alignment: .leading, spacing: 12) {
//                         Text("Pending Requests (\(pendingRequests.count))")
//                             .font(.system(size: 18, weight: .semibold))
                        
//                         ForEach(pendingRequests) { requester in
//                             HStack {
//                                 ParticipantView(user: requester)
//                                 Spacer()
//                                 Button(action: { acceptRequest(for: requester.id) }) {
//                                     Text("Accept")
//                                         .foregroundColor(.white)
//                                         .padding(.horizontal, 16)
//                                         .padding(.vertical, 8)
//                                         .background(Color.black)
//                                         .cornerRadius(8)
//                                 }
//                             }
//                         }
//                     }
//                     .padding(.horizontal)
//                 }
                
//                 // Join Button (if not creator and not full)
//                 if !isCreator && !isParticipant && !run.isFull {
//                     Button(action: requestToJoin) {
//                         Text(hasRequestedToJoin ? "Request Pending" : "Request to Join")
//                             .font(.system(size: 16, weight: .semibold))
//                             .foregroundColor(.white)
//                             .frame(maxWidth: .infinity)
//                             .padding()
//                             .background(hasRequestedToJoin ? Color.gray : Color.black)
//                             .cornerRadius(12)
//                     }
//                     .disabled(hasRequestedToJoin)
//                     .padding()
//                 }
                
//                 VStack(spacing: 12) {
//                     if isCreator {
//                         // Creator Actions
//                         HStack(spacing: 16) {
//                             Button(action: { showingEditSheet = true }) {
//                                 Label("Edit Run", systemImage: "pencil")
//                                     .frame(maxWidth: .infinity)
//                                     .padding()
//                                     .background(Color.gray.opacity(0.1))
//                                     .cornerRadius(12)
//                             }
                            
//                             Button(action: { showingDeleteAlert = true }) {
//                                 Label("Delete", systemImage: "trash")
//                                     .frame(maxWidth: .infinity)
//                                     .padding()
//                                     .background(Color.red.opacity(0.1))
//                                     .foregroundColor(.red)
//                                     .cornerRadius(12)
//                             }
//                         }
//                         .padding(.horizontal)
//                     } else if isParticipant {
//                         // Participant Actions
//                         Button(action: unjoinRun) {
//                             Text("Leave Run")
//                                 .frame(maxWidth: .infinity)
//                                 .padding()
//                                 .background(Color.red.opacity(0.1))
//                                 .foregroundColor(.red)
//                                 .cornerRadius(12)
//                         }
//                         .padding(.horizontal)
//                     }
//                 }
//             }
//         }
//         .navigationBarTitleDisplayMode(.inline)
//         .alert("Delete Run", isPresented: $showingDeleteAlert) {
//             Button("Cancel", role: .cancel) { }
//             Button("Delete", role: .destructive) { deleteRun() }
//         } message: {
//             Text("Are you sure you want to delete this run? This action cannot be undone.")
//         }
//         .sheet(isPresented: $showingEditSheet) {
//             EditRunView(run: run)
//         }
//         .alert(alertMessage, isPresented: $showingAlert) {
//             Button("OK", role: .cancel) { }
//         }
//         .onAppear {
//             verifyAndFetchData()
//         }
//     }
    
//     private var menuButton: some View {
//         Menu {
//             Button(action: { showingEditSheet = true }) {
//                 Label("Edit Run", systemImage: "pencil")
//             }
//             Button(role: .destructive, action: { showingDeleteAlert = true }) {
//                 Label("Delete Run", systemImage: "trash")
//             }
//         } label: {
//             Image(systemName: "ellipsis")
//                 .padding(8)
//                 .contentShape(Rectangle())
//         }
//     }
    
//     private func verifyAndFetchData() {
//         // Verify run ID
//         guard !run.id.isEmpty else {
//             print("Error: Run ID is empty")
//             return
//         }
        
//         // Verify creator ID
//         guard !run.createdBy.isEmpty else {
//             print("Error: Creator ID is empty")
//             return
//         }
        
//         fetchCreatorInfo()
//         fetchParticipants()
//         fetchPendingRequests()
//     }
    
//     private func fetchCreatorInfo() {
//         let db = Firestore.firestore()
//         db.collection("users").document(run.createdBy).getDocument { snapshot, error in
//             if let error = error {
//                 print("Error fetching creator info: \(error.localizedDescription)")
//                 return
//             }
//             guard let data = snapshot?.data() else { return }
//             creatorName = data["name"] as? String ?? "Unknown"
//             creatorProfileUrl = data["profileImageUrl"] as? String ?? ""
//         }
//     }
    
//     private func fetchParticipants() {
//         participants.removeAll() // Clear the existing participants
//         let db = Firestore.firestore() // Initialize Firestore

//         // Fetch each participant's data
//         for userId in run.currentParticipants {
//             guard !userId.isEmpty else { continue }         
//             // Make sure the document exists in Firestore
//             db.collection("users").document(userId).getDocument { (snapshot, error) in
//                 if let error = error {
//                     print("Error fetching participant: \(error.localizedDescription)")
//                     return
//                 }

//                 // Ensure the document exists
//                 guard let data = snapshot?.data() else {
//                     print("Participant document does not exist")
//                     return
//                 }

//                 // Create a User object and append it to the participants array
//                 let user = User(id: userId, data: data)

//                 // Update the participants array on the main thread
//                 DispatchQueue.main.async {
//                     participants.append(user)
//                 }
//             }
//         }
//     }

    
//     private func fetchPendingRequests() {
//         pendingRequests.removeAll()
//         for userId in run.joinRequests {
//             guard !userId.isEmpty else { continue }
            
//             let db = Firestore.firestore()
//             db.collection("users").document(userId).getDocument { snapshot, error in
//                 if let error = error {
//                     print("Error fetching request: \(error.localizedDescription)")
//                     return
//                 }
//                 if let data = snapshot?.data() {
//                     let user = User(id: userId, data: data)
//                     pendingRequests.append(user)
//                 }
//             }
//         }
//     }
    
//     private func checkJoinRequest() {
//         guard let userId = Auth.auth().currentUser?.uid else { return }
//         hasRequestedToJoin = run.joinRequests.contains(userId)
//     }
    
//     private func requestToJoin() {
//         guard let userId = Auth.auth().currentUser?.uid else { return }
//         guard !isLoading else { return }
        
//         isLoading = true
//         let db = Firestore.firestore()
        
//         db.collection("runs").document(run.id).updateData([
//             "joinRequests": FieldValue.arrayUnion([userId])
//         ]) { error in
//             isLoading = false
//             if let error = error {
//                 alertMessage = "Error requesting to join: \(error.localizedDescription)"
//                 showingAlert = true
//             } else {
//                 hasRequestedToJoin = true
//             }
//         }
//     }
    
//     private func acceptRequest(for userId: String) {
//         guard !isLoading else { return }
//         isLoading = true
        
//         let db = Firestore.firestore()
//         db.collection("runs").document(run.id).updateData([
//             "currentParticipants": FieldValue.arrayUnion([userId]),
//             "joinRequests": FieldValue.arrayRemove([userId])
//         ]) { error in
//             isLoading = false
//             if let error = error {
//                 alertMessage = "Error accepting request: \(error.localizedDescription)"
//                 showingAlert = true
//             } else {
//                 pendingRequests.removeAll { $0.id == userId }
//                 fetchParticipants()
//             }
//         }
//     }
    
//     private func formatDateTime(_ date: Date) -> String {
//         let formatter = DateFormatter()
//         formatter.dateStyle = .long
//         formatter.timeStyle = .short
//         return formatter.string(from: date)
//     }
    
//     private func unjoinRun() {
//         guard let userId = Auth.auth().currentUser?.uid else { return }
//         guard !isLoading else { return }
        
//         isLoading = true
//         let db = Firestore.firestore()
        
//         db.collection("runs").document(run.id).updateData([
//             "currentParticipants": FieldValue.arrayRemove([userId])
//         ]) { error in
//             isLoading = false
//             if let error = error {
//                 alertMessage = "Error leaving run: \(error.localizedDescription)"
//                 showingAlert = true
//             } else {
//                 // Navigate back after successfully leaving
//                 presentationMode.wrappedValue.dismiss()
//             }
//         }
//     }
    
//     private func deleteRun() {
//         guard isCreator else { return }
//         guard !isLoading else { return }
        
//         isLoading = true
//         let db = Firestore.firestore()
        
//         db.collection("runs").document(run.id).delete { error in
//             isLoading = false
//             if let error = error {
//                 alertMessage = "Error deleting run: \(error.localizedDescription)"
//                 showingAlert = true
//             } else {
//                 // Navigate back after successful deletion
//                 presentationMode.wrappedValue.dismiss()
//             }
//         }
//     }
// }

// struct ParticipantView: View {
//     let user: User
    
//     var body: some View {
//         VStack {
//             AsyncImage(url: URL(string: user.profileImageUrl)) { image in
//                 image
//                     .resizable()
//                     .aspectRatio(contentMode: .fill)
//             } placeholder: {
//                 Circle()
//                     .fill(Color.gray.opacity(0.3))
//             }
//             .frame(width: 50, height: 50)
//             .clipShape(Circle())
            
//             Text(user.name)
//                 .font(.system(size: 12))
//                 .lineLimit(1)
//         }
//         .frame(width: 60)
//     }
// }

// struct StatItem: View {
//     let title: String
//     let value: String
//     let icon: String
    
//     var body: some View {
//         VStack(spacing: 8) {
//             Image(systemName: icon)
//                 .font(.system(size: 24))
//             Text(value)
//                 .font(.system(size: 16, weight: .semibold))
//             Text(title)
//                 .font(.system(size: 12))
//                 .foregroundColor(.gray)
//         }
//     }
// }
